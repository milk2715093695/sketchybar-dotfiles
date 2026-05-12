-- 基本配置项
return {
    paddings = 3.5,
    group_paddings = 4,
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
