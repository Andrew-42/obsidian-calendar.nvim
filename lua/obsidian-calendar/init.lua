-- init.lua
-- Main module for obsidian-calendar plugin

local M = {}
local calendar = require("obsidian-calendar.calendar")

-- Default configuration
M.config = {
    -- Configuration options will be added here later
}

-- Setup function to allow user configuration
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)
end

-- Open the calendar view
function M.open()
    calendar.show()
end

return M
