local calendar = require("obsidian-calendar.calendar")
local file_utils = require("obsidian-calendar.file_utils")

--- @class ObsidianCalendarHighlights
--- @field border string: Window border characters (│, ─)
--- @field header string: Month/year title line
--- @field weekdays string: Weekday names row (Mo Tu We Th Fr)
--- @field today string: Today's date cell (`[N]`)
--- @field day string: Regular weekday cells
--- @field weekend string: Saturday/Sunday and Czech national holiday cells
--- @field separator string: Horizontal separator under the header
--- @field help string: Help text (footer hint and help view body)

--- @class ObsidianCalendarConfig
--- @field daily_notes_dir string: Directory containing daily notes (~ is expanded)
--- @field obsidian { enabled: boolean }: obsidian.nvim integration — when enabled, opening a missing note delegates to `:ObsidianToday <offset>`
--- @field highlights ObsidianCalendarHighlights: Highlight group links (set as `default`, so user overrides win)
--- @field day_highlight (fun(cell: DayCell): string|nil)?: Override per-day highlight; called for every non-today cell, return a hl group or nil for defaults

local M = {}

--- @type ObsidianCalendarConfig
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
    day_highlight = nil,
}

--- Initialize the plugin with user configuration.
--- @param opts ObsidianCalendarConfig?: User config; merged over defaults
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
