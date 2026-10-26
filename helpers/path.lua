-- Copyright (C) 2026 MRK.
-- SPDX-License-Identifier: GPL-3.0-only

local config_dir = os.getenv("CONFIG_DIR")

if not config_dir or config_dir == "" then
    local source = debug.getinfo(1, "S").source:gsub("^@", "")
    config_dir = source:match("^(.*)/helpers/path%.lua$")

    if config_dir and config_dir:sub(1, 1) ~= "/" then
        config_dir = (os.getenv("PWD") or ".") .. "/" .. config_dir:gsub("^%./", "")
    end
end

assert(
    config_dir and config_dir ~= "" and config_dir:sub(1, 1) == "/",
    "sketchybar: cannot resolve an absolute config dir"
)

config_dir = config_dir:gsub("/+$", "")

return {
    config_dir = config_dir,
    path = function(relative)
        return config_dir .. "/" .. relative
    end,
}
