local settings = require("config.settings")
local colors = require("config.colors")

-- Padding item required because of bracket
sbar.add("item", "right.calendar.padding", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", "right.calendar", {
    icon = {
        color = colors.palette.white,
        padding_left = 8,
        font = {
            style = settings.font.style_map["Black"],
            size = 12.0,
        },
    },
    label = {
        color = colors.palette.white,
        padding_right = 8,
        width = 49,
        align = "right",
        font = { family = settings.font.numbers },
    },
    position = "right",
    update_freq = 30,
    padding_left = 1,
    padding_right = 1,
    background = {
        color = colors.bg.bg1,
        border_color = colors.palette.black,
        border_width = 1
    },
    click_script = "open -a 'Calendar'"
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
    background = {
        color = colors.palette.transparent,
        height = 30,
        border_color = colors.palette.grey,
    }
})

-- Padding item required because of bracket
sbar.add("item", "right.calendar.padding", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
    cal:set({ icon = os.date("%m-%d %a"), label = os.date("%H:%M") })
end)
