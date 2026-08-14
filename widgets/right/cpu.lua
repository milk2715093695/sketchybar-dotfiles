local icons = require("config.icons")          -- 加载图标配置
local colors = require("config.colors")         -- 加载颜色配置
local settings = require("config.settings")     -- 加载设置配置
local spacer = require("helpers.spacer")       -- 统一间距 spacer

sbar.exec("pkill -f 'cpu_load cpu_update' 2>/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("graph", "right.cpu", 42, {
    position = "right",
    padding_left = 0,
    padding_right = settings.content_padding,
    graph = { color = colors.palette.blue },
    background = {
        height = 22,
        color = { alpha = 0 },
        border_color = { alpha = 0 },
        drawing = true,
    },
    icon = {
        string = icons.cpu,
        padding_left = settings.content_padding,
        padding_right = settings.content_padding,
    },
    label = {
        string = "cpu ??%",
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = 9.0,
        },
        align = "left",
        -- 负 padding 左移 label 至 graph 左缘对齐；偏移 = graph 数据点数 42
        padding_left = -42,
        padding_right = settings.content_padding,
        width = 0,
        y_offset = 4,
    },
})

sbar.add("bracket", "right.cpu.bracket", { cpu.name }, {
    background = { color = colors.bg.bg1 },
})

spacer.add("right.cpu.padding")

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
