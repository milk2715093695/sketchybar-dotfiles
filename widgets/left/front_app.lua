-- Derived from FelixKratz/dotfiles (GPL-3.0-only).
-- Copyright (C) Felix Kratz.
-- Copyright (C) 2026 MRK (modifications).
-- SPDX-License-Identifier: GPL-3.0-only

local settings = require("config.settings")    -- 加载设置配置

local front_app = sbar.add("item", "left.front_app", {
    display = "active",
    icon = { drawing = false },
    label = {
        font = {
            style = settings.font.style_map["Black"],
            size = 12.0,
        },
    },
    updates = true,
})

front_app:subscribe("front_app_switched", function(env)
    front_app:set({ label = { string = env.INFO } })
end)

front_app:subscribe("mouse.clicked", function(env)
    sbar.trigger("swap_menus_and_spaces")
end)
