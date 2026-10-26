-- Copyright (C) 2026 MRK.
-- SPDX-License-Identifier: GPL-3.0-only

local M = { mode = "spaces" }

local listeners = {}
local providers = {}

function M.get()
    return M.mode
end

function M.is(mode)
    return M.mode == mode
end

function M.set(mode)
    if mode == M.mode then return end
    M.mode = mode
    for _, listener in ipairs(listeners) do
        listener(mode)
    end
end

function M.toggle()
    M.set(M.is("spaces") and "menus" or "spaces")
end

function M.subscribe(listener)
    listeners[#listeners + 1] = listener
end

function M.register(name)
    providers[name] = true
end

function M.has(name)
    return providers[name] == true
end

return M
