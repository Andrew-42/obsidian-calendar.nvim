local calendar = require("obsidian-calendar.calendar")
local file_utils = require("obsidian-calendar.file_utils")

local M = {}

M.config = {
    daily_notes_dir = "~/path/to/your/daily-notes/",
    obsidian = { enabled = true },
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

    if not file_utils.validate_daily_notes_dir(M.config.daily_notes_dir) then
        local err_msg = string.format("Daily notes directory does not exist: %s", M.config.daily_notes_dir)
        vim.notify(err_msg, vim.log.levels.ERROR)
        M.disabled = true
        return
    end
end

function M.open()
    if M.disabled then
        local err_msg = string.format("Invalid plugin config. Fix the config and reload the plugin!")
        vim.notify(err_msg, vim.log.levels.ERROR)
        return
    end
    calendar.show()
end

return M
