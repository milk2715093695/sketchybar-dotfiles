-- 优先使用 install_sketchybar.sh --icons-only 下载的生成物；
-- 缺失或损坏时回退到仓库内置的锁定快照，保证 require 永不失败。
local ok, generated = pcall(require, "config.icon_map_generated")
if ok and type(generated) == "table" and next(generated) ~= nil then
    return generated
end
return require("config.icon_map_fallback")
