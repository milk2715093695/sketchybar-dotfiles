-- Copyright (C) 2026 MRK.
-- SPDX-License-Identifier: GPL-3.0-only

-- 基本配置项
local composite_edge = 10

return {
    paddings = 3,           -- 默认 icon+label padding / 部分 label 左距
    item_gap = 4,           -- 卡片间距：普通 item 左右各取一半，bracket 结构按需补齐
    content_padding = 8,    -- item 内部呼吸：icon/label 距 item 边缘
    font = require("config.default_font"),
    max_icons_per_ws = 5,   -- 每个 aerospace 的 workspaces 最多显示多少个图标
    max_menus = 15,         -- 最多显示 15 个菜单项
    menus_bin = "$CONFIG_DIR/helpers/menus/bin/menus",  -- menus helper 二进制（click_script/sbar.exec 中展开 $CONFIG_DIR）

    -- 系统环境
    network = {
        interface = "en0",      -- 默认网络接口
        service   = "Wi-Fi",    -- networksetup 中的服务名
    },

    -- 社交 App（依赖 LaunchServices StatusLabel）
    social = {
        apps = {
            { id = "wechat",      bundle = "com.tencent.xinWeChat",   icon = "WeChat" },
            { id = "qq",          bundle = "com.tencent.qq",          icon = "QQ" },
            { id = "thunderbird", bundle = "org.mozilla.thunderbird", icon = "Thunderbird" },
        },
    },

    -- 复合 item 间距
    composite_paddings = {
        icon = {
            padding_left = composite_edge,
            padding_right = 5,
        },
        label = {
            padding_right = composite_edge,
        },
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
