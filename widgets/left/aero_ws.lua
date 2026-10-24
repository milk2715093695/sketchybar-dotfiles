local colors = require("config.colors")            -- 加载颜色配置
local settings = require("config.settings")        -- 加载设置配置
local icon_map = require("config.icon_map")        -- 加载应用图标配置
local json = require("helpers.lunajson.lunajson")  -- 加载 json 解析库
local ui_mode = require("helpers.ui_mode")         -- 加载 UI 模式状态

local workspace_items = {}
local workspace_data = {
    all_ws = {},
    monitor_map = {},
    focused_ws = nil,
    ws_windows = {}
}
local last_workspace = nil

local get_all_ws = "aerospace list-workspaces --all --format '%{workspace} %{monitor-appkit-nsscreen-screens-id} %{workspace-is-focused}' --json"
local get_all_windows = "aerospace list-windows --all --format '%{workspace} %{app-name}' --json"

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
    if not ui_mode.is("spaces") then return end

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
            if not seen[app] then
                seen[app] = true
                count = count + 1

                if count > max_icons then
                    table.insert(icons_to_show, "...")
                    break
                end

                table.insert(icons_to_show, icon_map[app] or icon_map["Default"])
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

-- 全量刷新：初始加载、切换 workspace、显示器变化等
local function refresh_workspace_data()
    coroutine.wrap(function()
        local all_ws = async_exec(get_all_ws)
        if type(all_ws) ~= "table" then return end

        local windows = async_exec(get_all_windows)
        if type(windows) ~= "table" then return end

        local monitor_map, ws_windows, focused_ws = {}, {}, nil
        for _, ws in ipairs(all_ws) do
            local ws_id = ws.workspace
            monitor_map[ws_id] = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
            ws_windows[ws_id] = {}
            if ws["workspace-is-focused"] then focused_ws = ws_id end
        end

        local seen = {}
        for _, win in ipairs(windows) do
            local ws_id, app = win.workspace, win["app-name"]
            if ws_windows[ws_id] and app then
                seen[ws_id] = seen[ws_id] or {}
                if not seen[ws_id][app] then
                    seen[ws_id][app] = true
                    table.insert(ws_windows[ws_id], app)
                end
            end
        end

        workspace_data.monitor_map = monitor_map
        workspace_data.ws_windows = ws_windows
        if focused_ws then workspace_data.focused_ws = focused_ws end

        for ws_id in pairs(workspace_items) do
            update_workspace(ws_id, workspace_data)
        end
    end)()
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
        -- XXX: 无窗口关闭事件，焦点重排时兜底全量刷新；焦点窗口关闭时事件早于窗口销毁，
        --      可能拉到中间态（图标残留），下次切换纠正（见下方总述）
        refresh_workspace_data()
    elseif evt._event == "focused-monitor-changed" then
        refresh_workspace_data()
    end
end

-- XXX: subscribe 无 window-removed 事件（aerospace 0.21 事件全集），窗口状态机做不到纯增量。
--      切换 / 焦点变化时全量快照兜底；拉取失败则保留旧图标（宁可旧不错）

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
            click_script = string.format("aerospace workspace %q", ws_id),
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

ui_mode.register("spaces")

ui_mode.subscribe(function(mode)
    if mode == "spaces" then
        refresh_workspace_data()
    else
        sbar.set("/left\\.aero_workspace\\..*/", { drawing = false })
    end
end)

-- 初始化 workspace 数据
init_workspace_items()
refresh_workspace_data()
