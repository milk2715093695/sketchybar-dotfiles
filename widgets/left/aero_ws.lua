-- Copyright (C) 2026 MRK.
-- SPDX-License-Identifier: GPL-3.0-only

local colors = require("config.colors")            -- 加载颜色配置
local settings = require("config.settings")        -- 加载设置配置
local icon_map = require("config.icon_map")        -- 加载应用图标配置
local ui_mode = require("helpers.ui_mode")         -- 加载 UI 模式状态
local shell = require("helpers.shell")             -- 加载 shell 转义工具

local workspace_items = {}
local workspace_order = {}
local anchor_name = "left.aero_workspace_anchor"
local workspace_data = {
    monitor_map = {},
    focused_ws = nil,
    apps_by_ws = {}
}

local get_ws_ids = "aerospace list-workspaces --all --format '%{workspace}'"
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

-- 更新单个 workspace 显示
local function update_workspace(ws_id, snapshot)
    if not ui_mode.is("spaces") then return end

    local monitor_id = snapshot.monitor_map[ws_id] or 1
    local apps = snapshot.apps_by_ws[ws_id] or {}
    local is_empty = #apps == 0
    local focused = snapshot.focused_ws == ws_id
    local border_color = focused
        and colors.aerospace.hover_border_color
        or colors.aerospace.border_color

    -- 非空 workspace
    if not is_empty then
        local seen = {}
        local count = 0
        local max_icons = settings.max_icons_per_ws
        local icons_to_show = {}

        for _, app in ipairs(apps) do
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
            icon = { highlight = focused },
            label = {
                string = table.concat(icons_to_show, " "),
                highlight = focused,
            },
            display = monitor_id,
            background = { border_color = border_color },
        })
        return
    end

    -- 空 workspace
    if focused then
        workspace_items[ws_id]:set({
            drawing = true,
            icon = { highlight = true },
            label = { string = "-", highlight = true },
            display = monitor_id,
            background = { border_color = colors.aerospace.hover_border_color },
        })
    else
        workspace_items[ws_id]:set({ drawing = false })
    end
end

-- 切换 workspace 后用户应先看到高亮立即移动，不等异步快照；事件已代表切换成功，快照只做校正。
local function update_focus(new_ws, prev_ws)
    if not new_ws or new_ws == workspace_data.focused_ws then return end

    prev_ws = prev_ws or workspace_data.focused_ws
    workspace_data.focused_ws = new_ws

    if prev_ws and workspace_items[prev_ws] then
        update_workspace(prev_ws, workspace_data)
    end
    if workspace_items[new_ws] then
        update_workspace(new_ws, workspace_data)
    end
end

-- 全量刷新：初始加载、切换 workspace、显示器变化等
local refresh_seq = 0

local function create_workspace_item(ws_id, drawing)
    local ws_item = sbar.add("item", "left.aero_workspace." .. ws_id, {
        drawing = drawing,
        icon = {
            string = ws_id,
            color = colors.aerospace.icon_color,
            highlight_color = colors.aerospace.icon_highlight_color,
        },
        label = {
            color = colors.aerospace.label_color,
            highlight_color = colors.aerospace.label_highlight_color,
            font = "sketchybar-app-font:Regular:14.0",
        },
        background = { color = colors.bg.bg1 },
    })

    workspace_items[ws_id] = ws_item

    ws_item:subscribe("mouse.clicked", function(env)
        if env.BUTTON == "right" then
            sbar.exec("aerospace move-node-to-workspace -- " .. shell.quote(ws_id))
            return
        end
        if env.BUTTON ~= "left" then return end
        if ws_id == workspace_data.focused_ws then return end

        -- 点击先移动高亮，并作废在途快照；失败则 resync 回滚
        refresh_seq = refresh_seq + 1
        update_focus(ws_id, workspace_data.focused_ws)
        sbar.exec("aerospace workspace -- " .. shell.quote(ws_id) ..
            " || sketchybar --trigger aerospace_resync")
    end)

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

    return ws_item
end

-- workspace 集合变化时增删 item，并保持顺序稳定
local function sync_workspace_items(desired, seq)
    local desired_set = {}
    for _, ws_id in ipairs(desired) do
        desired_set[ws_id] = true
    end

    for ws_id in pairs(workspace_items) do
        if not desired_set[ws_id] then
            sbar.remove("left.aero_workspace." .. ws_id)
            workspace_items[ws_id] = nil
            workspace_data.apps_by_ws[ws_id] = nil
            workspace_data.monitor_map[ws_id] = nil
        end
    end

    local new_items = {}
    for _, ws_id in ipairs(desired) do
        if not workspace_items[ws_id] then
            create_workspace_item(ws_id, false)
            new_items[#new_items + 1] = ws_id
        end
    end

    local order_changed = #workspace_order ~= #desired
    if not order_changed then
        for i, ws_id in ipairs(desired) do
            if workspace_order[i] ~= ws_id then
                order_changed = true
                break
            end
        end
    end

    if #new_items == 0 and not order_changed then
        workspace_order = desired
        return false
    end

    local command = { "sketchybar" }
    for _, ws_id in ipairs(desired) do
        command[#command + 1] = "--move"
        command[#command + 1] = shell.quote("left.aero_workspace." .. ws_id)
        command[#command + 1] = "before"
        command[#command + 1] = shell.quote(anchor_name)
    end

    sbar.exec(table.concat(command, " "), function(_, exit_code)
        if seq ~= refresh_seq then return end

        if exit_code ~= 0 then
            print("sketchybar: workspace reorder failed: " .. tostring(exit_code))
            for _, ws_id in ipairs(desired) do
                if workspace_items[ws_id] then
                    update_workspace(ws_id, workspace_data)
                end
            end
            return
        end

        workspace_order = desired
        for _, ws_id in ipairs(desired) do
            if workspace_items[ws_id] then
                update_workspace(ws_id, workspace_data)
            end
        end
    end)
    return true
end

local function refresh_workspace_data()
    refresh_seq = refresh_seq + 1
    local seq = refresh_seq

    coroutine.wrap(function()
        local all_ws = async_exec(get_all_ws)
        if seq ~= refresh_seq or type(all_ws) ~= "table" then return end

        if #all_ws == 0 then
            print("sketchybar: ignoring empty AeroSpace workspace list")
            return
        end

        local windows = async_exec(get_all_windows)
        if seq ~= refresh_seq or type(windows) ~= "table" then return end

        local monitor_map, apps_by_ws, focused_ws = {}, {}, nil
        for _, ws in ipairs(all_ws) do
            local ws_id = ws.workspace
            monitor_map[ws_id] = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
            apps_by_ws[ws_id] = {}
            if ws["workspace-is-focused"] then focused_ws = ws_id end
        end

        local seen = {}
        for _, win in ipairs(windows) do
            local ws_id, app = win.workspace, win["app-name"]
            if apps_by_ws[ws_id] and app then
                seen[ws_id] = seen[ws_id] or {}
                if not seen[ws_id][app] then
                    seen[ws_id][app] = true
                    table.insert(apps_by_ws[ws_id], app)
                end
            end
        end

        workspace_data.monitor_map = monitor_map
        workspace_data.apps_by_ws = apps_by_ws
        workspace_data.focused_ws = focused_ws

        local desired = {}
        for _, ws in ipairs(all_ws) do
            desired[#desired + 1] = ws.workspace
        end
        if sync_workspace_items(desired, seq) then return end

        for ws_id in pairs(workspace_items) do
            update_workspace(ws_id, workspace_data)
        end
    end)()
end

-- 仅刷新窗口快照：复用 workspace 元数据；未知 workspace 或退化为空时回退全量
local function refresh_windows_data(focused_ws)
    refresh_seq = refresh_seq + 1
    local seq = refresh_seq

    coroutine.wrap(function()
        local windows = async_exec(get_all_windows)
        if seq ~= refresh_seq or type(windows) ~= "table" then return end

        local apps_by_ws = {}
        for ws_id in pairs(workspace_items) do
            apps_by_ws[ws_id] = {}
        end

        local seen = {}
        for _, win in ipairs(windows) do
            local ws_id, app = win.workspace, win["app-name"]
            if not workspace_items[ws_id] then
                refresh_workspace_data()
                return
            end

            if app then
                seen[ws_id] = seen[ws_id] or {}
                if not seen[ws_id][app] then
                    seen[ws_id][app] = true
                    table.insert(apps_by_ws[ws_id], app)
                end
            end
        end

        -- workspace 退化为空时无法仅靠窗口列表判断是否已被删除
        for ws_id, apps in pairs(workspace_data.apps_by_ws) do
            if #apps > 0 and #(apps_by_ws[ws_id] or {}) == 0 then
                refresh_workspace_data()
                return
            end
        end

        workspace_data.apps_by_ws = apps_by_ws
        workspace_data.focused_ws = focused_ws

        for ws_id in pairs(workspace_items) do
            update_workspace(ws_id, workspace_data)
        end
    end)()
end

-- AeroSpace 重启但 sketchybar 未重启时，先清掉旧高亮，再异步拉全量快照
local function resync_workspace_data()
    workspace_data.focused_ws = nil
    for ws_id in pairs(workspace_items) do
        update_workspace(ws_id, workspace_data)
    end
    refresh_workspace_data()
end

-- 处理 aerospace subscribe 推送的增量事件
local function handle_aerospace_event(env)
    -- SbarLua 已将 JSON env 值自动解析为 Lua 表
    local evt = env.EVENT_JSON
    if not evt or not evt._event then return end

    if evt._event == "focused-workspace-changed" then
        update_focus(evt.workspace, evt.prevWorkspace)
        -- subscribe 无窗口关闭事件：切换时全量扫描兜底，纠正所有 workspace 的残留图标
        refresh_workspace_data()
    elseif evt._event == "window-detected" then
        if not workspace_items[evt.workspace] then
            refresh_workspace_data()
            return
        end

        local apps = workspace_data.apps_by_ws[evt.workspace] or {}
        local found = false
        for _, app in ipairs(apps) do
            if app == evt.appName then
                found = true
                break
            end
        end

        if not found then
            table.insert(apps, evt.appName)
            workspace_data.apps_by_ws[evt.workspace] = apps
            update_workspace(evt.workspace, workspace_data)
        end
    elseif evt._event == "focus-changed" then
        update_focus(evt.workspace)
        -- XXX: 无窗口关闭事件，焦点重排时兜底窗口快照；未知 workspace 或退化为空时回退全量
        if evt.workspace and workspace_items[evt.workspace] then
            refresh_windows_data(evt.workspace)
        else
            refresh_workspace_data()
        end
    elseif evt._event == "focused-monitor-changed" then
        refresh_workspace_data()
    end
end

-- XXX: subscribe 无 window-removed 事件（aerospace 0.21 事件全集），窗口状态机做不到纯增量。
--      切换 / 焦点变化时全量快照兜底；拉取失败则保留旧图标（宁可旧不错）

-- 创建 workspace item：同步取 ID 以保证加载顺序，完整数据由 refresh 异步填充
local function init_workspace_items()
    local ok, ws_ids = pcall(function()
        local handle = io.popen(get_ws_ids)
        local output = handle:read("*a")
        handle:close()

        local ids = {}
        for line in output:gmatch("[^\r\n]+") do
            ids[#ids + 1] = line
        end
        return ids
    end)
    if not ok then
        print("sketchybar: failed to query AeroSpace workspaces: " .. tostring(ws_ids))
        return
    end

    if #ws_ids == 0 then
        print("sketchybar: AeroSpace returned no workspaces")
    end

    for _, ws_id in ipairs(ws_ids) do
        create_workspace_item(ws_id, true)
    end
    workspace_order = ws_ids
end

-- 注册 aerospace subscribe 转发事件
sbar.add("event", "aerospace_event")

-- 先建初始 workspace，锚点才能固定在组右边界
init_workspace_items()

-- 锚点固定 workspace 组右边界，新 item 先移入再排序
local refresh_item = sbar.add("item", anchor_name, {
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false, border_width = 0 },
    padding_left = 0,
    padding_right = 0,
})

refresh_item:subscribe("aerospace_event", handle_aerospace_event)

refresh_item:subscribe("aerospace_resync", resync_workspace_data)

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
refresh_workspace_data()
