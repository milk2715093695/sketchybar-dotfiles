local colors = require("config.colors")        -- 加载颜色配置
local settings = require("config.settings")    -- 加载设置配置
local icon_map = require("config.icon_map")  	-- 加载应用图标配置
local json = require("helpers.lunajson.lunajson")	-- 加载 json 解析库

local M = {}

local workspace_items = {}
local workspace_data = {
    all_ws = {},
    monitor_map = {},
    empty_ws = {},
    focused_ws = nil,
    ws_windows = {}
}
local last_workspace = nil

local get_all_ws = "aerospace list-workspaces --all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"
local get_empty_ws = "aerospace list-workspaces --monitor focused --empty --json"
local get_focused_ws = "aerospace list-workspaces --focused --json"
local get_all_windows = "aerospace list-windows --all --format '%{workspace}%{app-name}' --json"

-- 协程辅助函数
local function async_exec(cmd)
    local co = coroutine.running()
    sbar.exec(cmd, function(result)
        coroutine.resume(co, result)
    end)
    return coroutine.yield()
end

-- 获取 workspace 基本数据（平铺）
local function get_workspace_data(callback)
    coroutine.wrap(function()
        local all_ws = async_exec(get_all_ws)
        local empty_ws = async_exec(get_empty_ws)
        local focused_ws = async_exec(get_focused_ws)
        local all_windows = async_exec(get_all_windows)

        -- 处理数据
        local monitor_map = {}
        for _, ws in ipairs(all_ws) do
            monitor_map[ws.workspace] = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
        end

        local empty_ws_set = {}
        for _, ws in ipairs(empty_ws) do
            empty_ws_set[ws.workspace] = true
        end

        local focused_ws_id = (#focused_ws > 0) and focused_ws[1].workspace or nil

        local ws_windows = {}
        for _, win in ipairs(all_windows) do
            local ws = win.workspace
            ws_windows[ws] = ws_windows[ws] or {}
            table.insert(ws_windows[ws], win["app-name"])
        end

        workspace_data.all_ws = all_ws
        workspace_data.monitor_map = monitor_map
        workspace_data.empty_ws = empty_ws_set
        workspace_data.focused_ws = focused_ws_id
        workspace_data.ws_windows = ws_windows

        callback(workspace_data)
    end)()
end

-- 更新单个 workspace 显示
local function update_workspace(ws_id, workspace_data)
    local monitor_id = workspace_data.monitor_map[ws_id] or 1
    local open_windows = workspace_data.ws_windows[ws_id] or {}
    local is_empty = workspace_data.empty_ws[ws_id] or false

    -- 用于初始化后初次显示
    if not last_workspace and workspace_data.focused_ws == ws_id then
        last_workspace = ws_id
        workspace_items[ws_id]:set({
            drawing = true,
            icon = { highlight = true },
            label = { highlight = true },
            display = monitor_id,
            background = { border_color = colors.aerospace.hover_border_color },
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
        })
    else
        workspace_items[ws_id]:set({ drawing = false })
    end
end

-- 刷新 workspace 数据
local function refresh_workspace_data()
    get_workspace_data(function()
        for ws_id in pairs(workspace_items) do
            update_workspace(ws_id, workspace_data)
        end
    end)
end

-- 创建 workspace item，进行初始化时阻塞以确保加载顺序
local function init_workspace_items()
    local result = io.popen(get_all_ws):read("*a")

    workspace_data.all_ws = json.decode(result)
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

-- 创建一个隐藏 refresh 组件，只订阅一次事件
local refresh_item = sbar.add("item", {
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 0,
    padding_right = 0,
})

refresh_item:subscribe(
    { "aerospace_focus_change", "display_change" },
    refresh_workspace_data
)

refresh_item:subscribe("aerospace_workspace_change", function(env)
    local ws_id = env.FOCUSED_WORKSPACE

    if last_workspace and last_workspace ~= ws_id then
        workspace_items[last_workspace]:set({
            icon = { highlight = false },
            label = { highlight = false },
            background = { border_color = colors.aerospace.border_color },
        })
    end

    last_workspace = ws_id

    workspace_items[ws_id]:set({
        icon = { highlight = true },
        label = { highlight = true },
        background = { border_color = colors.aerospace.hover_border_color },
    })
end)

-- 初始化 workspace 数据
init_workspace_items()
refresh_workspace_data()

M.refresh = refresh_workspace_data
return M
