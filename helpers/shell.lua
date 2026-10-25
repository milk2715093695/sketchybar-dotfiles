local M = {}

-- 生成可安全插入 POSIX shell 的单引号字符串
function M.quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

return M
