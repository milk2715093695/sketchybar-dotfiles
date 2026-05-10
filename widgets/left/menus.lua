local colors = require("config.colors")        -- 加载颜色配置
local settings = require("config.settings")    -- 加载设置配置
local icons = require("config.icons")          -- 加载图标配置

local aero_ws_enabled = false
for _, cfg in ipairs(settings.layout.left) do
    if cfg.name == "aero_ws" and cfg.enabled then
        aero_ws_enabled = true
        break
    end
end

local aerospace
if aero_ws_enabled then
    aerospace = require("widgets.left.aero_ws")
else
    -- 占位对象，保证 refresh() 可调用
    aerospace = {
        refresh = function() end
    }
end

-- 菜单管理器
local menu_manager = sbar.add("item", {
    drawing = false,
    updates = false,
})

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
        click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
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
local switch_button = sbar.add("item", {
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
    sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
        sbar.set('/left\\.menu\\..*/', { drawing = false })
        menu_padding:set({ drawing = true })

        local id = 1
        for menu in string.gmatch(menus, '[^\r\n]+') do
            if id <= max_items then
                menu_items[id]:set({ label = menu, drawing = true })
            else
                break
            end
            id = id + 1
        end
    end)
end

-- 监听前台应用切换
menu_manager:subscribe("front_app_switched", refresh_menus)

-- 切换按钮事件处理
switch_button:subscribe("swap_menus_and_spaces", function()
    local showing_menus = menu_items[1]:query().geometry.drawing == "on"

    if showing_menus then
        menu_manager:set({ updates = false })
        sbar.set("/left\\.menu\\..*/", { drawing = false })

        -- 展开工作区
        sbar.set("/left\\.aero_workspace\\..*/", { drawing = true })
        aerospace.refresh()
    else
        menu_manager:set({ updates = true })

        -- 收起工作区
        sbar.set("/left\\.aero_workspace\\..*/", { drawing = false })
        refresh_menus()
    end

    -- 切换图标
    local currently_on = switch_button:query().icon.value == icons.switch.on
    switch_button:set({ icon = currently_on and icons.switch.off or icons.switch.on })
end)

-- 鼠标点击触发切换
switch_button:subscribe("mouse.clicked", function()
    sbar.trigger("swap_menus_and_spaces")
end)

-- 监听工作区切换事件
switch_button:subscribe("aerospace_workspace_change", function(env)
    menu_manager:set({ updates = false })
    sbar.set("/left\\.menu\\..*/", { drawing = false })
    switch_button:set({ icon = icons.switch.off })
end)

return menu_manager
