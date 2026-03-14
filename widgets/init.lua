local settings = require("config.settings")    -- 加载设置

-- 根据设置布局加载 widget
local function load_widgets(side)
    for _, cfg in ipairs(settings.layout[side]) do
        if cfg.enabled then
            local widget = require("widgets." .. side .. "." .. cfg.name)
        end
    end
end

load_widgets("left")
load_widgets("right")
