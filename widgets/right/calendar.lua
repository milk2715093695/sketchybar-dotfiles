local settings = require("config.settings") -- 加载设置配置
local colors = require("config.colors")     -- 加载颜色配置
local spacer = require("helpers.spacer")    -- 统一间距 spacer

local cal = sbar.add("item", "right.calendar", {
    icon = {
        color = colors.palette.white,
        font = {
            style = settings.font.style_map["Black"],
            size = 12.0,
        },
    },
    label = {
        color = colors.palette.white,
        width = 49,
        align = "right",
        font = { family = settings.font.numbers },
    },
    position = "right",
    update_freq = 30,
    background = { color = colors.bg.bg1 },
    click_script = "open -a 'Calendar'",
})

spacer.add("right.calendar.padding")

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
    cal:set({ icon = os.date("%m-%d %a"), label = os.date("%H:%M") })
end)
