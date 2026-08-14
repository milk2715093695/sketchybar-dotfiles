local colors = require("config.colors")         -- 加载颜色配置
local icons = require("config.icons")           -- 加载图标配置
local settings = require("config.settings")     -- 加载设置配置
local spacer = require("helpers.spacer")       -- 统一间距 spacer

local popup_width = 250

local volume_percent = sbar.add("item", "right.volume.percent", {
    position = "right",
    padding_right = settings.content_padding,
    padding_left = 0,
    icon = { drawing = false },
    label = {
        string = "??%",
        padding_left = settings.paddings,
        font = { family = settings.font.numbers },
    },
})

local volume_icon = sbar.add("item", "right.volume.icon", {
    position = "right",
    padding_left = settings.content_padding,
    padding_right = 0,
    icon = {
        string = icons.volume._100,
        width = 0,
        align = "left",
        color = colors.palette.grey,
        font = {
            style = settings.font.style_map["Regular"],
            size = 14.0,
        },
    },
    label = {
        width = 25,
        align = "left",
        padding_right = settings.paddings,
        font = {
            style = settings.font.style_map["Regular"],
            size = 14.0,
        },
    },
})

local volume_bracket = sbar.add("bracket", "right.volume.bracket", {
    volume_icon.name,
    volume_percent.name,
}, {
    background = { color = colors.bg.bg1 },
    popup = { align = "center" },
})

spacer.add("right.volume.padding")

local volume_slider = sbar.add("slider", popup_width, {
    position = "popup." .. volume_bracket.name,
    slider = {
        highlight_color = colors.palette.blue,
        background = {
            height = 6,
            corner_radius = 3,
            color = colors.bg.bg1,
        },
        knob = {
            string = "􀀁",
            drawing = true,
        },
    },
    background = { color = colors.bg.bg1, height = 2, y_offset = -20 },
    click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

volume_percent:subscribe("volume_change", function(env)
    local volume = tonumber(env.INFO)
    local icon = icons.volume._0
    if volume > 60 then
        icon = icons.volume._100
    elseif volume > 30 then
        icon = icons.volume._66
    elseif volume > 10 then
        icon = icons.volume._33
    elseif volume > 0 then
        icon = icons.volume._10
    end

    local lead = ""
    if volume < 10 then
        lead = "0"
    end

    volume_icon:set({ label = icon })
    volume_percent:set({ label = lead .. volume .. "%" })
    volume_slider:set({ slider = { percentage = volume } })
end)

local function volume_collapse_details()
    local drawing = volume_bracket:query().popup.drawing == "on"
    if not drawing then return end
    volume_bracket:set({ popup = { drawing = false } })
    sbar.remove('/volume.device\\.*/')
end

local current_audio_device = "None"
local function volume_toggle_details(env)
    if env.BUTTON == "right" then
        sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
        return
    end

    local should_draw = volume_bracket:query().popup.drawing == "off"
    if should_draw then
        volume_bracket:set({ popup = { drawing = true } })
        sbar.exec("SwitchAudioSource -t output -c", function(result)
            current_audio_device = result:sub(1, -2)
            sbar.exec("SwitchAudioSource -a -t output", function(available)
                local current_device = current_audio_device
                local color = colors.palette.grey
                local counter = 0

                for device in string.gmatch(available, '[^\r\n]+') do
                    local color = colors.palette.grey
                    if current_device == device then
                        color = colors.palette.white
                    end
                    sbar.add("item", "volume.device." .. counter, {
                        position = "popup." .. volume_bracket.name,
                        width = popup_width,
                        align = "center",
                        label = { string = device, color = color },
                        click_script = 'SwitchAudioSource -s "' .. device .. '" && sketchybar --set /volume.device\\.*/ label.color=' .. colors.palette.grey .. ' --set $NAME label.color=' .. colors.palette.white,
                    })
                    counter = counter + 1
                end
            end)
        end)
    else
        volume_collapse_details()
    end
end

local function volume_scroll(env)
    local delta = env.INFO.delta
    if not (env.INFO.modifier == "ctrl") then delta = delta * 10.0 end

    sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end

volume_icon:subscribe("mouse.clicked", volume_toggle_details)
volume_icon:subscribe("mouse.scrolled", volume_scroll)
volume_percent:subscribe("mouse.clicked", volume_toggle_details)
volume_percent:subscribe("mouse.exited.global", volume_collapse_details)
volume_percent:subscribe("mouse.scrolled", volume_scroll)
