local icons = require("config.icons")          -- 加载图标配置
local colors = require("config.colors")         -- 加载颜色配置
local settings = require("config.settings")     -- 加载设置配置

sbar.exec("pkill -f 'cpu_load cpu_update' 2>/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("graph", "right.cpu", 42, {
    position = "right",
    graph = { color = colors.palette.blue },
    background = {
        height = 22,
        color = { alpha = 0 },
        border_color = { alpha = 0 },
        drawing = true,
    },
    icon = { string = icons.cpu },
    label = {
        string = "cpu ??%",
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = 9.0,
        },
        align = "right",
        padding_right = 0,
        width = 0,
        y_offset = 4,
    },
    padding_right = settings.paddings + 6,
})

cpu:subscribe("cpu_update", function(env)
    -- Also available: env.user_load, env.sys_load
    local load = tonumber(env.total_load)
    cpu:push({ load / 100. })

    local color = colors.palette.blue
    if load > 30 then
        if load < 60 then
            color = colors.palette.yellow
        elseif load < 80 then
            color = colors.palette.orange
        else
            color = colors.palette.red
        end
    end

    cpu:set({
        graph = { color = color },
        label = "cpu " .. env.total_load .. "%",
    })
end)

cpu:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a 'Activity Monitor'")
end)

-- Background around the cpu item
sbar.add("bracket", "right.cpu.bracket", { cpu.name }, {
    background = { color = colors.bg.bg1 },
})

-- Padding item for the cpu bracket
sbar.add("item", "right.cpu.padding", {
    position = "right",
    width = settings.group_paddings,
})
