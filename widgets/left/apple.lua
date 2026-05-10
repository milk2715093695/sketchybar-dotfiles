local colors = require("config.colors")        -- 加载颜色配置
local icons = require("config.icons")          -- 加载图标配置

-- 加载辅助函数
local popup_helper = require("helpers.popup")

-- apple 图标
local apple_logo = sbar.add("item", "left.apple.logo", {
    position = "left",
    icon = {
        font = { size = 16.0 },
        string = icons.apple,
        color = colors.palette.blue,
        padding_right = 8,
        padding_left = 8,
    },
    label = { drawing = false },
    padding_left = 1,
    padding_right = 1,
    popup = {
        height = 0,
        drawing = false,
    }
})

-- 点击切换 popup 状态
apple_logo:subscribe("mouse.clicked", function(_)
    apple_logo:set({ popup = { drawing = "toggle" } })
end)

-- 子条目 1：关于本机
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.laptop,
    label_str = "关于本机",
    click_cmd = "open -b com.apple.SystemProfiler",
    subscribe_click = true,
})

-- 分割线
popup_helper.add_divider({ parent = apple_logo })

-- 子条目 2：系统设置
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.gear,
    label_str = "系统设置",
    click_cmd = "open -b com.apple.systempreferences",
    subscribe_click = true,
})

-- 分割线
popup_helper.add_divider({ parent = apple_logo })

-- 子条目 3：睡眠
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.sleep,
    label_str = "睡眠",
    click_cmd = "pmset sleepnow",
    subscribe_click = true,
})

-- 子条目 4：重启
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.refresh,
    label_str = "重新启动",
    click_cmd = "osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'",
    subscribe_click = true,
})

-- 子条目 5：关机
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.power,
    label_str = "关机",
    click_cmd = "osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'",
    subscribe_click = true,
})

-- 分割线
popup_helper.add_divider({ parent = apple_logo })

-- 子条目 6：锁定屏幕
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.lock,
    label_str = "锁定屏幕",
    click_cmd = "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,control down}'",
    subscribe_click = true,
})

-- 子条目 7：退出登录
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.account,
    label_str = "退出登录",
    click_cmd = "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,shift down}'",
    subscribe_click = true,
})

-- 分割线
popup_helper.add_divider({ parent = apple_logo })

-- 子条目 8：调用原生菜单
popup_helper.add_popup_item({
    parent = apple_logo,
    icon_str = icons.apple,
    label_str = "原生菜单",
    click_cmd = "$HOME/.config/sketchybar/helpers/menus/bin/menus -s 0",
    subscribe_click = true,
})
