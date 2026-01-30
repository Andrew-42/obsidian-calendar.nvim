local M = {}

--- Checks if a file exists
--- @param filepath string: Absolute path to file
--- @return boolean: True if file exists and is readable
function M.file_exists(filepath)
    return vim.fn.filereadable(filepath) == 1
end

--- Checks if a date has been notified as missing
--- @param date_key string: Date in "yyyy-mm-dd" format
--- @param notified_set table: Set of notified dates
--- @return boolean: True if already notified
function M.is_date_notified(date_key, notified_set)
    return notified_set[date_key] == true
end

--- Adds a date to the notified set
--- @param date_key string: Date in "yyyy-mm-dd" format
--- @param notified_set table: Set of notified dates
function M.mark_date_notified(date_key, notified_set)
    notified_set[date_key] = true
end

--- Formats date object to string key
--- @param date Date: Date object with year, month, day fields
--- @return string: Formatted as "yyyy-mm-dd"
function M.date_to_key(date)
    return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

return M
