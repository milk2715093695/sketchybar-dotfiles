local settings = require("config.settings")    -- 加载设置配置

-- 统一 widget 间距：默认宽度来自 settings.item_gap，可按需覆盖
-- 避免每个 widget 文件重复粘贴 item 配置
local M = {}

function M.add(name, width)
    sbar.add("item", name, {
        position = "right",
        icon = { drawing = true, padding_left = 0, padding_right = 0 },
        label = { drawing = true, padding_left = 0, padding_right = 0 },
        padding_left = 0,
        padding_right = 0,
        background = { drawing = false },
        width = width or settings.item_gap,
    })
end

return M
