-- Require the sketchybar module
-- FelixKratz/SbarLua 提供
-- sbar 是本仓库中**唯一允许的全局变量**，仅供 SketchyBar API 入口使用
sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()
require("bar")
require("config.default")
require("widgets")
sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
