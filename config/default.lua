local settings = require("config.settings")    -- 设置
local colors = require("config.colors")        -- 颜色设置

-- Equivalent to the --default domain
sbar.default({
    updates = "when_shown", -- item 更新时机

    -- 状态栏图标配置
    icon = {
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Bold"],
            size = 14.0,
        },
        color = colors.palette.white,
        padding_left = settings.paddings,
        padding_right = settings.paddings,
        background = { image = { corner_radius = 9 } },
    },

    -- 默认 label 配置
    label = {
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Semibold"],
            size = 13.0,
        },
        color = colors.palette.white,
        padding_left = settings.paddings,
        padding_right = settings.paddings,
    },

    -- 默认背景设置
    background = {
        height = 30,
        corner_radius = 9,
        border_width = 2,
        border_color = colors.bg.bg2,
        image = {
            corner_radius = 9,
            border_color = colors.palette.grey,
            border_width = 1,
        },
    },

    -- 弹出小窗口设置
    popup = {
        background = {
            border_width = 2,
            corner_radius = 9,
            border_color = colors.popup.border,
            color = colors.popup.bg,
            shadow = { drawing = true },
        },
        blur_radius = 20,
    },

    blur_radius = 40,
    padding_left = 2,
    padding_right = 2,
    scroll_texts = true,
})
