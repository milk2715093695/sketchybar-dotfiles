local colors = require("config.colors")        -- 加载颜色配置
local settings = require("config.settings")    -- 加载设置配置
local icon_map = require("config.icon_map")  	-- 加载应用图标配置
local json = require("helpers.lunajson.lunajson")	-- 加载 json 解析库

local M = {}

local workspace_items = {}
local workspace_data = {
    all_ws = {},
    monitor_map = {},
    focused_ws = nil,
    ws_windows = {}
}
local last_workspace = nil

local get_all_ws = "aerospace list-workspaces --all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"
local get_focused_ws = "aerospace list-workspaces --focused --json"
-- 命令含 %{...} 格式符，不能过 string.format（会把 %{ 当转换符），拆开拼接
local get_ws_windows = "aerospace list-windows --workspace "
local get_ws_windows_suffix = " --format '%{app-name}' --json"

-- 协程辅助函数
local function async_exec(cmd)
    local co = coroutine.running()
    sbar.exec(cmd, function(result)
        coroutine.resume(co, result)
    end)
    return coroutine.yield()
end

-- 高亮 / 取消高亮指定 workspace
-- 定义在 update_workspace 之前：init 刷新链可能在模块加载期间同步执行，local 前向引用会崩
local function highlight_ws(ws_id)
    if not workspace_items[ws_id] then return end

    workspace_items[ws_id]:set({
        icon = { highlight = true },
        label = { highlight = true },
        background = { border_color = colors.aerospace.hover_border_color },
    })
end

local function unhighlight_ws(ws_id)
    if not workspace_items[ws_id] then return end

    workspace_items[ws_id]:set({
        icon = { highlight = false },
        label = { highlight = false },
        background = { border_color = colors.aerospace.border_color },
    })
end

-- 更新单个 workspace 显示
local function update_workspace(ws_id, workspace_data)
    local monitor_id = workspace_data.monitor_map[ws_id] or 1
    local open_windows = workspace_data.ws_windows[ws_id] or {}
    local is_empty = #open_windows == 0

    -- 用于初始化后初次显示
    if not last_workspace and workspace_data.focused_ws == ws_id then
        last_workspace = ws_id
        highlight_ws(ws_id)
        workspace_items[ws_id]:set({
            drawing = true,
            display = monitor_id,
        })
    end

    -- 非空 workspace
    if not is_empty then
        local seen = {}
        local count = 0
        local max_icons = settings.max_icons_per_ws
        local icons_to_show = {}

        for _, app in ipairs(open_windows) do
            local icon = icon_map[app] or icon_map["Default"]

            if not seen[icon] then
                count = count + 1

                if count > max_icons then
                    table.insert(icons_to_show, "...")
                    break
                end

                table.insert(icons_to_show, icon)
                seen[icon] = true
            end
        end

        workspace_items[ws_id]:set({
            drawing = true,
            label = { string = table.concat(icons_to_show, " ") },
            display = monitor_id,
        })
        return
    end

    -- 空 workspace
    if workspace_data.focused_ws == ws_id then
        workspace_items[ws_id]:set({
            drawing = true,
            label = { string = '-' },
            display = monitor_id,
        })
    else
        workspace_items[ws_id]:set({ drawing = false })
    end
end

-- 拉取指定 workspace 的窗口列表并刷新该 workspace 显示
local function refresh_ws(ws_id)
    coroutine.wrap(function()
        if not workspace_items[ws_id] then return end

        -- pcall 只包可能抛错的异步执行；命令失败时 result 是错误字符串，ipairs 前必须判型
        local ok, result = pcall(async_exec, get_ws_windows .. ws_id .. get_ws_windows_suffix)
        if not ok or type(result) ~= "table" then return end

        local seen, apps = {}, {}
        for _, win in ipairs(result) do
            local app = win["app-name"]
            if app and not seen[app] then
                seen[app] = true
                apps[#apps + 1] = app
            end
        end
        workspace_data.ws_windows[ws_id] = apps
        update_workspace(ws_id, workspace_data)
    end)()
end

-- 全量刷新：初始加载、显示器变化等低频场景
local function refresh_workspace_data()
    coroutine.wrap(function()
        local all_ws = async_exec(get_all_ws)
        if type(all_ws) ~= "table" then return end

        local monitor_map = {}
        for _, ws in ipairs(all_ws) do
            monitor_map[ws.workspace] = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
        end
        workspace_data.monitor_map = monitor_map

        local focused = async_exec(get_focused_ws)
        if type(focused) == "table" and #focused > 0 then
            workspace_data.focused_ws = focused[1].workspace
        end

        for ws_id in pairs(workspace_items) do
            refresh_ws(ws_id)
        end
    end)()
end

-- 按缓存数据同步决定所有 workspace 的显示状态（不等待异步刷新）
-- 供 menus.lua 收起菜单时调用，避免先全绘再隐藏空 workspace 的闪烁
local function show_workspaces()
    for ws_id in pairs(workspace_items) do
        update_workspace(ws_id, workspace_data)
    end
end

-- 处理 aerospace subscribe 推送的增量事件
local function handle_aerospace_event(env)
    -- SbarLua 已将 JSON env 值自动解析为 Lua 表
    local evt = env.EVENT_JSON
    if not evt or not evt._event then return end

    if evt._event == "focused-workspace-changed" then
        if last_workspace and last_workspace ~= evt.workspace then
            unhighlight_ws(last_workspace)
            -- 空 workspace 失焦后要隐藏，否则 '-' 指示符残留
            if #(workspace_data.ws_windows[last_workspace] or {}) == 0 then
                workspace_items[last_workspace]:set({ drawing = false })
            end
        end

        last_workspace = evt.workspace
        workspace_data.focused_ws = evt.workspace
        highlight_ws(evt.workspace)
        -- subscribe 无窗口关闭事件：切换时全量扫描兜底，纠正所有 workspace 的残留图标
        refresh_workspace_data()
    elseif evt._event == "window-detected" then
        -- XXX: 窗口图标按 icon 去重，多个 app 共用同一 icon 时后到的被吞
        local apps = workspace_data.ws_windows[evt.workspace] or {}
        local found = false
        for _, app in ipairs(apps) do
            if app == evt.appName then
                found = true
                break
            end
        end

        if not found then
            table.insert(apps, evt.appName)
            workspace_data.ws_windows[evt.workspace] = apps
            if workspace_items[evt.workspace] then
                update_workspace(evt.workspace, workspace_data)
            end
        end
    elseif evt._event == "focus-changed" then
        -- XXX: 无窗口关闭事件，焦点重排时兜底刷新；焦点窗口关闭时事件早于窗口销毁，
        --      可能拉到中间态（图标残留），下次切换纠正（见下方总述）
        if evt.workspace then
            refresh_ws(evt.workspace)
        end
    elseif evt._event == "focused-monitor-changed" then
        refresh_workspace_data()
    end
end

-- XXX: subscribe 无 window-removed 事件（aerospace 0.21 事件全集），窗口状态机做不到纯增量。
--      切换时全量扫描兜底，focus-changed 时 scoped 拉取兜底；拉取失败则保留旧图标（宁可旧不错）

-- 创建 workspace item，进行初始化时阻塞以确保加载顺序
local function init_workspace_items()
    local ok, result = pcall(function()
        local handle = io.popen(get_all_ws)
        local data = handle:read("*a")
        handle:close()
        return json.decode(data)
    end)
    if not ok then return end
    
    workspace_data.all_ws = result
    for _, ws in ipairs(workspace_data.all_ws) do
        local ws_id = ws.workspace

        local ws_item = sbar.add("item", "left.aero_workspace." .. ws_id ,{
            icon = {
                string = ws_id,
                color = colors.aerospace.icon_color,
                highlight_color = colors.aerospace.icon_highlight_color,
                font = {
                    size = 14.0,
                    style = settings.font.style_map["Heavy"],
                },
                padding_left = 10,
                padding_right = 5,
            },
            label = {
                color = colors.aerospace.label_color,
                highlight_color = colors.aerospace.label_highlight_color,
                font = "sketchybar-app-font:Regular:14.0",
                padding_right = 10,
            },
            background = { color = colors.bg.bg1 },
            click_script = "aerospace workspace " .. ws_id,
        })

        workspace_items[ws_id] = ws_item

        ws_item:subscribe("mouse.entered", function()
            workspace_items[ws_id]:set({
                background = { border_color = colors.aerospace.hover_border_color },
            })
        end)

        ws_item:subscribe("mouse.exited", function()
            if ws_id == workspace_data.focused_ws then
                workspace_items[ws_id]:set({
                    background = { border_color = colors.aerospace.hover_border_color }
                })
            else
                workspace_items[ws_id]:set({
                    background = { border_color = colors.aerospace.border_color },
                })
            end
        end)
    end
end

-- 注册 aerospace subscribe 转发事件
sbar.add("event", "aerospace_event")

-- 创建一个隐藏 refresh 组件，只订阅一次事件
local refresh_item = sbar.add("item", {
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 0,
    padding_right = 0,
})

refresh_item:subscribe("aerospace_event", handle_aerospace_event)

refresh_item:subscribe("display_change", refresh_workspace_data)

-- 初始化 workspace 数据
init_workspace_items()
refresh_workspace_data()

M.show = show_workspaces
M.refresh = refresh_workspace_data
return M
