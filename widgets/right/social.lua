local colors = require("config.colors")        -- 加载颜色配置
local icon_map = require("config.icon_map")    -- 加载图标配置
local spacer = require("helpers.spacer")       -- 统一间距 spacer

local M = {}

-- 通用函数生成 app widget
local function create_app_widget(app_name, bundle_id)
    local widget = sbar.add("item", "right." .. app_name:lower(), {
        position = "right",
        icon = {
            font = "sketchybar-app-font:Regular:16.0",
            string = icon_map[app_name],
            color = colors.palette.white,
        },
        update_freq = 5,
    })

    widget:subscribe({"routine", "system_woke"}, function()
        sbar.exec("lsappinfo -all info \"" .. bundle_id .. "\"", function(app_notify)
            local notify_num = app_notify:match('"StatusLabel"=%{ "label"="?(.-)"? %}')

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
        sbar.exec("open -b " .. bundle_id)
    end)

    return widget
end

M.wechat = create_app_widget("WeChat", "com.tencent.xinWeChat")
M.qq = create_app_widget("QQ", "com.tencent.qq")

-- wechat/qq 为透明 item，刻意紧贴；外部间距由组尾 spacer 统一
spacer.add("right.social.padding")

return M
