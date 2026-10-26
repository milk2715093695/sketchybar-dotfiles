-- Copyright (C) 2026 MRK.
-- SPDX-License-Identifier: GPL-3.0-only

local colors = require("config.colors")         -- 加载颜色配置
local icon_map = require("config.icon_map")     -- 加载图标配置
local settings = require("config.settings")     -- 加载全局配置
local shell = require("helpers.shell")          -- shell 参数转义

local M = {}

-- 通用函数生成 app widget
local function create_app_widget(app)
    local widget = sbar.add("item", "right." .. app.id, {
        position = "right",
        icon = {
            font = "sketchybar-app-font:Regular:16.0",
            string = (app.icon and icon_map[app.icon]) or icon_map["Default"],
            color = colors.palette.white,
            padding_left = settings.paddings,
            padding_right = settings.paddings,
        },
        label = {
            padding_right = settings.paddings,
        },
        update_freq = 5,
    })

    widget:subscribe({"routine", "system_woke"}, function()
        sbar.exec("lsappinfo -all info " .. shell.quote(app.bundle), function(app_notify)
            local notify_num = app_notify and app_notify:match('"StatusLabel"=%{ "label"="?(.-)"? %}')

            if notify_num == nil or notify_num == "" then
                widget:set({ label = { drawing = false } })
            else
                widget:set({
                    label = {
                        string = notify_num,
                        drawing = true,
                    },
                })
            end
        end)
    end)

    widget:subscribe("mouse.clicked", function(env)
        if env.BUTTON ~= "left" then return end
        sbar.exec("open -b " .. shell.quote(app.bundle))
    end)

    return widget
end

for _, app in ipairs(settings.social.apps) do
    M[app.id] = create_app_widget(app)
end

return M
