-- /Users/<username>/.local/share/sketchybar_lua/?.so
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

-- 检查 helper 二进制，缺失时提示但不阻塞启动
local helpers = {
    "helpers/menus/bin/menus",
    "helpers/event_providers/cpu_load/bin/cpu_load",
    "helpers/event_providers/network_load/bin/network_load",
}
for _, path in ipairs(helpers) do
    local f = io.open(path, "r")
    if f then
        f:close()
    else
        print("sketchybar: helper binary not found: " .. path .. " (run install script or 'cd helpers && make')")
    end
end
