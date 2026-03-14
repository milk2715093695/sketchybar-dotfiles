-- /Users/<username>/.local/share/sketchybar_lua/?.so
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

-- 编译 helpers
os.execute("(cd helpers && make)")
