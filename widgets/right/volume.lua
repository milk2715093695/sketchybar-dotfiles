local colors = require("config.colors")         -- 加载颜色配置
local icons = require("config.icons")           -- 加载图标配置
local presets = require("config.presets")       -- 复合 item 间距
local settings = require("config.settings")     -- 加载设置配置
local spacer = require("helpers.spacer")        -- 统一间距 spacer
local shell = require("helpers.shell")          -- 加载 shell 转义

local popup_width = 250

local volume_item = sbar.add("item", "right.volume", {
    position = "right",
    icon = {
        string = icons.volume._100,
        width = 25,
        align = "left",
        color = colors.palette.white,
        padding_left = presets.composite.icon.padding_left,
        padding_right = presets.composite.icon.padding_right,
        font = {
            style = settings.font.style_map["Regular"],
            size = 14.0,
        },
    },
    label = {
        string = "??%",
        padding_left = settings.paddings,
        padding_right = presets.composite.label.padding_right,
        font = { family = settings.font.numbers },
    },
    background = { color = colors.bg.bg1 },
    popup = { align = "center" },
})

spacer.add("right.volume.padding")

local volume_slider = sbar.add("slider", popup_width, {
    position = "popup." .. volume_item.name,
    slider = {
        highlight_color = colors.palette.blue,
        background = {
            height = 6,
            corner_radius = 3,
            color = colors.bg.bg1,
        },
        knob = {
            string = "●",
            font = {
                family = settings.font.text,
                style = settings.font.style_map["Regular"],
                size = 10.0,
            },
            drawing = true,
        },
    },
    background = { color = colors.bg.bg1, height = 2, y_offset = -20 },
    click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

local function render_volume(volume, muted)
    local icon = icons.volume.mute
    if not muted then
        icon = icons.volume._0
        if volume > 60 then
            icon = icons.volume._100
        elseif volume > 30 then
            icon = icons.volume._66
        elseif volume > 10 then
            icon = icons.volume._33
        elseif volume > 0 then
            icon = icons.volume._10
        end
    end

    local color = muted and colors.palette.muted or colors.palette.white
    local lead = volume < 10 and "0" or ""
    volume_item:set({
        icon = { string = icon, color = color },
        label = { string = lead .. volume .. "%", color = color },
    })
    volume_slider:set({ slider = { percentage = volume } })
end

local function refresh_volume()
    sbar.exec([[osascript -e 'set v to output volume of (get volume settings)' -e 'set m to output muted of (get volume settings)' -e 'return (v as string) & "|" & (m as string)']], function(result)
        local volume, muted = result:match("(%d+)|(%a+)")
        if volume then
            render_volume(tonumber(volume), muted == "true")
        end
    end)
end

volume_item:subscribe("volume_change", function(env)
    render_volume(tonumber(env.INFO), false)
end)

local function volume_collapse_details()
    local drawing = volume_item:query().popup.drawing == "on"
    if not drawing then return end
    volume_item:set({ popup = { drawing = false } })
    sbar.remove('/volume.device\\.*/')
end

local current_audio_device = "None"
local function volume_toggle_details(env)
    if env.BUTTON == "right" then
        sbar.exec("osascript -e 'set volume output muted not (output muted of (get volume settings))'", refresh_volume)
        return
    end

    local should_draw = volume_item:query().popup.drawing == "off"
    if should_draw then
        volume_item:set({ popup = { drawing = true } })
        sbar.exec("SwitchAudioSource -t output -c", function(result)
            current_audio_device = result:sub(1, -2)
            sbar.exec("SwitchAudioSource -a -t output", function(available)
                local current_device = current_audio_device
                local counter = 0

                for device in string.gmatch(available, '[^\r\n]+') do
                    local color = colors.palette.grey
                    if current_device == device then
                        color = colors.palette.white
                    end
                    sbar.add("item", "volume.device." .. counter, {
                        position = "popup." .. volume_item.name,
                        width = popup_width,
                        align = "center",
                        label = { string = device, color = color },
                        click_script = "SwitchAudioSource -s " .. shell.quote(device) ..
                            " && sketchybar --set /volume.device\\.*/ label.color=" .. colors.palette.grey ..
                            " --set $NAME label.color=" .. colors.palette.white,
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

volume_item:subscribe("mouse.clicked", volume_toggle_details)
volume_item:subscribe("mouse.scrolled", volume_scroll)
volume_item:subscribe("mouse.exited.global", volume_collapse_details)

refresh_volume()
