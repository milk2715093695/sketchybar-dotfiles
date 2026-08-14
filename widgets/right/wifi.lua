local icons = require("config.icons")          -- 加载图标配置
local colors = require("config.colors")         -- 加载颜色配置
local settings = require("config.settings")     -- 加载设置配置
local spacer = require("helpers.spacer")       -- 统一间距 spacer

sbar.exec("pkill -f 'network_load.*network_update' 2>/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load " .. settings.network.interface .. " network_update 2.0")

local popup_width = 250

local wifi_up = sbar.add("item", "right.wifi.up", {
    position = "right",
    padding_left = -5,
    width = 0,
    icon = {
        padding_right = 0,
        font = {
            style = settings.font.style_map["Bold"],
            size = 9.0,
        },
        string = icons.wifi.upload,
    },
    label = {
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = 9.0,
        },
        color = colors.palette.red,
        string = "??? Bps",
        padding_right = settings.content_padding,
    },
    y_offset = 4,
})

local wifi_down = sbar.add("item", "right.wifi.down", {
    position = "right",
    padding_left = -5,
    icon = {
        padding_right = 0,
        font = {
            style = settings.font.style_map["Bold"],
            size = 9.0,
        },
        string = icons.wifi.download,
    },
    label = {
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = 9.0,
        },
        color = colors.palette.blue,
        string = "??? Bps",
        padding_right = settings.content_padding,
    },
    y_offset = -4,
})

local wifi = sbar.add("item", "right.wifi", {
    position = "right",
    padding_left = settings.content_padding,
    label = { drawing = false },
})

-- Background around the item
local wifi_bracket = sbar.add("bracket", "right.wifi.bracket", {
    wifi.name,
    wifi_up.name,
    wifi_down.name,
}, {
    background = { color = colors.bg.bg1 },
    popup = { align = "center", height = 30 },
})

local ssid = sbar.add("item", {
    position = "popup." .. wifi_bracket.name,
    icon = {
        font = {
            style = settings.font.style_map["Bold"],
        },
        string = icons.wifi.router,
    },
    width = popup_width,
    align = "center",
    label = {
        font = {
            size = 15,
            style = settings.font.style_map["Bold"],
        },
        max_chars = 18,
        string = "????????????",
    },
    background = {
        height = 2,
        color = colors.palette.grey,
        y_offset = -15,
    },
})

local hostname = sbar.add("item", {
    position = "popup." .. wifi_bracket.name,
    icon = {
        align = "left",
        string = "Hostname:",
        width = popup_width / 2,
    },
    label = {
        max_chars = 20,
        string = "????????????",
        width = popup_width / 2,
        align = "right",
    },
})

local ip = sbar.add("item", {
    position = "popup." .. wifi_bracket.name,
    icon = {
        align = "left",
        string = "IP:",
        width = popup_width / 2,
    },
    label = {
        string = "???.???.???.???",
        width = popup_width / 2,
        align = "right",
    },
})

local mask = sbar.add("item", {
    position = "popup." .. wifi_bracket.name,
    icon = {
        align = "left",
        string = "Subnet mask:",
        width = popup_width / 2,
    },
    label = {
        string = "???.???.???.???",
        width = popup_width / 2,
        align = "right",
    },
})

local router = sbar.add("item", {
    position = "popup." .. wifi_bracket.name,
    icon = {
        align = "left",
        string = "Router:",
        width = popup_width / 2,
    },
    label = {
        string = "???.???.???.???",
        width = popup_width / 2,
        align = "right",
    },
})

spacer.add("right.wifi.padding")

wifi_up:subscribe("network_update", function(env)
    local up_color = (env.upload == "000 Bps") and colors.palette.grey or colors.palette.red
    local down_color = (env.download == "000 Bps") and colors.palette.grey or colors.palette.blue
    wifi_up:set({
        icon = { color = up_color },
        label = {
            string = env.upload,
            color = up_color,
        },
    })
    wifi_down:set({
        icon = { color = down_color },
        label = {
            string = env.download,
            color = down_color,
        },
    })
end)

wifi:subscribe({"wifi_change", "system_woke"}, function(env)
    sbar.exec("ipconfig getifaddr " .. settings.network.interface, function(ip)
        local connected = not (ip == "")
        wifi:set({
            icon = {
                string = connected and icons.wifi.connected or icons.wifi.disconnected,
                color = connected and colors.palette.white or colors.palette.red,
            },
        })
    end)
end)

local function hide_details()
    wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
    local should_draw = wifi_bracket:query().popup.drawing == "off"
    if should_draw then
        wifi_bracket:set({ popup = { drawing = true } })
        sbar.exec("networksetup -getcomputername", function(result)
            hostname:set({ label = result })
        end)
        sbar.exec("ipconfig getifaddr " .. settings.network.interface, function(result)
            ip:set({ label = result })
        end)
        sbar.exec("ipconfig getsummary " .. settings.network.interface .. " | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
            ssid:set({ label = result })
        end)
        sbar.exec("networksetup -getinfo " .. settings.network.service .. " | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
            mask:set({ label = result })
        end)
        sbar.exec("networksetup -getinfo " .. settings.network.service .. " | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
            router:set({ label = result })
        end)
    else
        hide_details()
    end
end

wifi_up:subscribe("mouse.clicked", toggle_details)
wifi_down:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
    local label = sbar.query(env.NAME).label.value
    sbar.exec("echo \"" .. label .. "\" | pbcopy")
    sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
    sbar.delay(1, function()
        sbar.set(env.NAME, { label = { string = label, align = "right" } })
    end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
