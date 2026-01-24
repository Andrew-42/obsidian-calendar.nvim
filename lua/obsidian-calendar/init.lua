-- Main module for obsidian-calendar plugin

local M = {}
local calendar = require("obsidian-calendar.calendar")

M.config = {
    daily_notes_dir = "~/Personal/2_Areas/0_obsidian-notes/Daily Logs/",
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
