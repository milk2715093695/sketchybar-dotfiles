local colors = {}

-- 基础调色板
colors.palette = {
    black       = 0xFF1F2335,
    white       = 0xFFC0CAF5,
    red         = 0xFFF7768E,
    green       = 0xFF9ECE6A,
    blue        = 0xFF7AA2F7,
    yellow      = 0xFFE0AF68,
    orange      = 0xFFFF9E64,
    magenta     = 0xFFBB9AF7,
    grey        = 0xFF414868,
    transparent = 0x00000000,
}

-- Bar 配置
colors.bar = {
    bg      = colors.palette.transparent,
    border  = colors.palette.grey,
}

-- 弹窗
colors.popup = {
    bg      = 0xC02C2E34,
    border  = colors.palette.blue,
}

-- 背景层
colors.bg = {
    bg1 = 0xFF363944,
    bg2 = 0xFF414550,
}

-- Aerospace 组件
colors.aerospace = {
    icon_color              = colors.palette.blue,
    icon_highlight_color    = colors.palette.yellow,
    label_color             = colors.palette.white,
    label_highlight_color   = colors.palette.green,
    border_color            = colors.palette.grey,
    hover_border_color      = colors.palette.blue,
}

-- 工具函数
function colors.with_alpha(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00FFFFFF) | (math.floor(alpha * 255.0) << 24)
end

return colors
