-- 加载颜色
local colors = require("config.colors")

-- bar 配置
sbar.bar({
    color = colors.bar.bg,
    border_color = colors.bar.border,
    height = 35,
    -- margin = 0,
    -- corner_radius = 0,
    blur_radius = 20,
    padding_left = 5,
    padding_right = 5,
    -- hidden = "off",
    shadow = "on",
})
