local M = {}

--- Construct daily note filename from date
--- @param date Date: The date
--- @return string: Filename in format "yyyy-mm-dd.md"
function M.daily_note_filename(date)
    return string.format("%04d-%02d-%02d.md", date.year, date.month, date.day)
end

--- Validate and expand daily notes directory path
--- @param dir string: Directory path (may contain ~)
--- @return string|nil
function M.validate_daily_notes_dir(dir)
    local expanded = vim.fn.expand(dir)

    if vim.fn.isdirectory(expanded) == 0 then
        local err_msg = string.format("Daily notes directory does not exist: %s", expanded)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return nil
    end

    return expanded
end

--- Validate and expand daily notes directory path
--- @param date Date: The date of the note
--- @param dir string: Directory path (may contain ~)
--- @return string|nil
function M.daily_note_path(date, dir)
    local filename = M.daily_note_filename(date)

    local daily_notes_dir = M.validate_daily_notes_dir(dir)
    if not daily_notes_dir then
        return nil
    end

    return daily_notes_dir:gsub("/$", "") .. "/" .. filename
end

return M
