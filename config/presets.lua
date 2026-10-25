-- 复合 item 的显式间距约定：icon 左 10 / 右 5，label 右 10
local M = {}

M.composite = {
    icon = {
        padding_left = 10,
        padding_right = 5,
    },
    label = {
        padding_right = 10,
    },
}

return M
