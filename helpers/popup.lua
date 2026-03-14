local colors = require("config.colors")  -- 加载颜色配置

local M = {}

M.add_popup_item = function(args)
    local parent = args.parent
    local icon_str = args.icon_str
    local label_str = args.label_str
    local click_cmd = args.click_cmd
    local subscribe_click = args.subscribe_click

    -- 添加弹出框项
    local item = sbar.add("item", {
        position = "popup." .. parent.name,
        icon = { string = icon_str },
        label = { string = label_str },
        background = {
            color = colors.popup.transparent,
            height = 30,
            drawing = true,
            border_width = 0,
        },
    })

    -- 根据参数决定是否订阅点击事件
    if subscribe_click then
        item:subscribe("mouse.clicked", function(_)
            sbar.exec(click_cmd)
            parent:set({ popup = { drawing = false } })
        end)
    end
end

M.add_divider = function(args)
    local parent = args.parent

    sbar.add("item", {
        position = "popup." .. parent.name,
        icon = { drawing = false },
        label = { drawing = false },
        background = {
            color = colors.palette.blue,
            height = 1,
            drawing = true,
            border_width = 0,
        },
        padding_left = 7,
        padding_right = 7,
        width = 120,
    })
end

return M
