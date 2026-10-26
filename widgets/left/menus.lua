-- Derived from FelixKratz/dotfiles (GPL-3.0-only).
-- Copyright (C) Felix Kratz.
-- Copyright (C) 2026 MRK (modifications).
-- SPDX-License-Identifier: GPL-3.0-only

local colors = require("config.colors")        -- 加载颜色配置
local settings = require("config.settings")    -- 加载设置配置
local icons = require("config.icons")          -- 加载图标配置

local ui_mode = require("helpers.ui_mode")

-- 菜单项初始化
local max_items = settings.max_menus
local menu_items = {}

for i = 1, max_items do
    local menu = sbar.add("item", "left.menu." .. i, {
        padding_left = settings.paddings,
        padding_right = settings.paddings,
        drawing = false,
        icon = { drawing = false },
        label = {
            font = {
                style = settings.font.style_map[i == 1 and "Heavy" or "Semibold"]
            },
            padding_left = 6,
            padding_right = 6,
        },
        click_script = settings.menus_bin .. " -s " .. i,
    })
    menu_items[i] = menu
end

-- 所有 menu.* 放在 bracket 里
sbar.add("bracket", { '/left\\.menu\\..*/' }, {
    background = { color = colors.bg.bg1 }
})

-- 菜单右侧 padding
local menu_padding = sbar.add("item", "left.menu.padding", {
    drawing = false,
    width = 5
})

-- 菜单/空间切换按钮
local switch_button = sbar.add("item", "left.menus.toggle", {
    padding_left = -3,
    padding_right = 0,
    icon = {
        padding_left = 8,
        padding_right = 9,
        color = colors.palette.grey,
        string = icons.switch.on,
    },
    label = {
        width = 0,
        padding_left = 0,
        padding_right = 8,
        string = "Switch",
        color = colors.bg.bg1,
    },
    background = {
        color = colors.with_alpha(colors.palette.grey, 0.0),
        border_color = colors.with_alpha(colors.bg.bg1, 0.0),
    }
})

-- 刷新菜单函数
local function refresh_menus()
    sbar.exec(settings.menus_bin .. " -l", function(menus)
        local visible = not ui_mode.has("spaces") or ui_mode.is("menus")

        sbar.set('/left\\.menu\\..*/', { drawing = false })
        menu_padding:set({ drawing = visible })

        local id = 1
        for menu in string.gmatch(menus, '[^\r\n]+') do
            if id <= max_items then
                menu_items[id]:set({ label = menu, drawing = visible })
            else
                break
            end
            id = id + 1
        end
    end)
end

-- 监听前台应用切换：订阅挂在首个菜单项上，菜单可见时才收到事件
menu_items[1]:subscribe("front_app_switched", function()
    if ui_mode.has("spaces") and not ui_mode.is("menus") then return end

    refresh_menus()
end)

-- 根据模式同步菜单显隐与切换图标
ui_mode.subscribe(function(mode)
    switch_button:set({ icon = mode == "spaces" and icons.switch.on or icons.switch.off })

    if mode == "menus" then
        refresh_menus()
    else
        sbar.set("/left\\.menu\\..*/", { drawing = false })
        menu_padding:set({ drawing = false })
    end
end)

-- 切换按钮事件处理
switch_button:subscribe("swap_menus_and_spaces", function()
    ui_mode.toggle()
end)

-- 鼠标点击触发切换
switch_button:subscribe("mouse.clicked", function()
    sbar.trigger("swap_menus_and_spaces")
end)

-- 监听工作区切换事件
switch_button:subscribe("aerospace_workspace_change", function()
    if ui_mode.has("spaces") then
        ui_mode.set("spaces")
    end
end)

-- 配置加载完成后判断是否存在工作区视图：没有则隐藏切换按钮，菜单常显
sbar.exec("true", function()
    if ui_mode.has("spaces") then return end

    switch_button:set({ drawing = false })
    refresh_menus()
end)
