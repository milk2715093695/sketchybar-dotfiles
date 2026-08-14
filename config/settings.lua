-- 基本配置项
return {
    paddings = 3.5,         -- widget 外部间距（spacer 宽度）
    content_padding = 8,    -- item 内部呼吸：icon/label 距 item 边缘
    font = require("config.default_font"),
    max_icons_per_ws = 5,   -- 每个 aerospace 的 workspaces 最多显示多少个图标
    max_menus = 15,         -- 最多显示 15 个菜单项

    -- 系统环境
    network = {
        interface = "en0",      -- 默认网络接口
        service   = "Wi-Fi",    -- networksetup 中的服务名
    },

    -- 布局配置
    layout = {
        left = {
            { name = "apple", enabled = true },
            { name = "aero_ws", enabled = true },
            { name = "menus", enabled = true },
            { name = "front_app", enabled = true },
        },
        right = {
            { name = "calendar", enabled = true },
            { name = "battery", enabled = true },
            { name = "volume", enabled = true },
            { name = "wifi", enabled = true },
            { name = "cpu", enabled = true },
            { name = "social", enabled = true },
            { name = "media", enabled = false },
        }
    },
}
