local settings = require("config.settings")    -- 加载设置配置

local M = {}

function M.apply_popup(config)
    local p = settings.paddings
    config.icon = config.icon or {}
    config.label = config.label or {}
    config.icon.padding_left = p
    config.icon.padding_right = p
    config.label.padding_left = p
    config.label.padding_right = p
    return config
end

return M
