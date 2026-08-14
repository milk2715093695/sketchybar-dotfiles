local settings = require("config.settings")    -- 加载设置配置

-- 全局统一 widget 间距：每个 widget 尾随一个等宽 spacer，宽度来自 settings.paddings
-- 避免每个 widget 文件重复粘贴 item 配置
local M = {}

function M.add(name)
    sbar.add("item", name, {
        position = "right",
        icon = { drawing = true, padding_left = 0, padding_right = 0 },
        label = { drawing = true, padding_left = 0, padding_right = 0 },
        padding_left = 0,
        padding_right = 0,
        background = { drawing = false },
        width = settings.paddings,
    })
end

return M
