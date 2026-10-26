-- SbarLua 安装路径：$HOME/.local/share/sketchybar_lua/?.so
local home = os.getenv("HOME")
if home then
    package.cpath = package.cpath .. ";" .. home .. "/.local/share/sketchybar_lua/?.so"
end

local paths = require("helpers.path")

-- 检查 helper 二进制，缺失时提示但不阻塞启动
local helpers = {
    "helpers/menus/bin/menus",
    "helpers/event_providers/cpu_load/bin/cpu_load",
    "helpers/event_providers/network_load/bin/network_load",
}
for _, helper in ipairs(helpers) do
    local f = io.open(paths.path(helper), "r")
    if f then
        f:close()
    else
        print("sketchybar: helper binary not found: " .. helper .. " (run install script or 'cd helpers && make')")
    end
end
