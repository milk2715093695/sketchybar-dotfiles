-- Copyright (C) 2026 MRK.
-- SPDX-License-Identifier: GPL-3.0-only

local ok, generated = pcall(require, "config.icon_map_generated")
if ok and type(generated) == "table" and next(generated) ~= nil then
    return generated
end
return require("config.icon_map_fallback")
