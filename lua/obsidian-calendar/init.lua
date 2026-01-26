local calendar = require("obsidian-calendar.calendar")

local M = {}

M.config = {
    daily_notes_dir = "~/Personal/2_Areas/0_obsidian-notes/Daily Logs/",
    obsidian = {
        enabled = true,
        command = "ObsidianToday",
    },
    highlights = {
        border = "Delimiter",
        header = "Function",
        weekdays = "Identifier",
        today = "Special",
        day = "NONE",
        weekend = "Comment",
        separator = "Delimiter",
        help = "Comment",
    },
}

function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)
end

function M.open()
    calendar.show()
end

return M
