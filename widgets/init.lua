local settings = require("config.settings")    -- 加载设置

-- 可选依赖检查（命令缺失时跳过对应 widget）
local optional_deps = {
    aero_ws = "aerospace",
    volume  = "SwitchAudioSource",
    media   = "nowplaying-cli",
}

-- helper 二进制依赖（文件缺失时跳过对应 widget）
local helper_deps = {
    cpu   = "helpers/event_providers/cpu_load/bin/cpu_load",
    wifi  = "helpers/event_providers/network_load/bin/network_load",
    menus = "helpers/menus/bin/menus",
}

-- 检查命令是否存在
local function command_exists(cmd)
    return os.execute("command -v " .. cmd .. " >/dev/null 2>&1")
end

-- 根据设置布局加载 widget
local function load_widgets(side)
    for _, cfg in ipairs(settings.layout[side]) do
        if cfg.enabled then
            local skip = false

            local dep = optional_deps[cfg.name]
            if dep and not command_exists(dep) then
                print("sketchybar: skip " .. cfg.name .. " (" .. dep .. " not found)")
                skip = true
            end

            if not skip then
                local helper = helper_deps[cfg.name]
                if helper then
                    local f = io.open(helper, "r")
                    if f then
                        f:close()
                    else
                        print("sketchybar: skip " .. cfg.name .. " (helper binary not found)")
                        skip = true
                    end
                end
            end

            if not skip then
                local widget = require("widgets." .. side .. "." .. cfg.name)
            end
        end
    end
end

load_widgets("left")
load_widgets("right")
