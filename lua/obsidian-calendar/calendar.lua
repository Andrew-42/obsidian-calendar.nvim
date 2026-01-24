-- Calendar rendering and display logic

local M = {}

--- Check if year is a leap year
--- @param year number: The year to check
--- @return boolean: True if leap year
local function is_leap_year(year)
    return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

--- Get number of days in a month
--- @param year number: The year
--- @param month number: The month (1-12)
--- @return number: Days in the month (28-31)
local function days_in_month(year, month)
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 and is_leap_year(year) then
        return 29
    end
    return days[month]
end

--- Get first day of month as weekday number
--- @param year number: The year
--- @param month number: The month (1-12)
--- @return number: Day of week (1=Monday, 7=Sunday)
local function first_day_of_month(year, month)
    local time = os.time({ year = year, month = month, day = 1 })
    local wday = os.date("*t", time).wday
    -- Convert from Lua's Sunday=1 to Monday=1
    return wday == 1 and 7 or wday - 1
end

--- Get month name
--- @param month number: The month (1-12)
--- @return string: Month name
local function month_name(month)
    local names = {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    }
    return names[month]
end

--- Navigate to next month
--- @param year number: Current year
--- @param month number: Current month (1-12)
--- @return number, number: New year and month
local function next_month(year, month)
    if month == 12 then
        return year + 1, 1
    end
    return year, month + 1
end

--- Navigate to previous month
--- @param year number: Current year
--- @param month number: Current month (1-12)
--- @return number, number: New year and month
local function prev_month(year, month)
    if month == 1 then
        return year - 1, 12
    end
    return year, month - 1
end

--- Get current displayed month/year from buffer state
--- @param buf number: Buffer handle
--- @return number, number, number|nil: year, month, highlight_day
local function get_buffer_state(buf)
    local year = vim.api.nvim_buf_get_var(buf, "calendar_year")
    local month = vim.api.nvim_buf_get_var(buf, "calendar_month")
    local highlight_day = vim.b[buf].calendar_highlight_day
    return year, month, highlight_day
end

--- Set buffer state for displayed month/year
--- @param buf number: Buffer handle
--- @param year number: Year to display
--- @param month number: Month to display
--- @param highlight_day number|nil: Day to highlight
local function set_buffer_state(buf, year, month, highlight_day)
    vim.api.nvim_buf_set_var(buf, "calendar_year", year)
    vim.api.nvim_buf_set_var(buf, "calendar_month", month)
    vim.api.nvim_buf_set_var(buf, "calendar_highlight_day", highlight_day)
end

--- Repeat text n times
--- @param text string
--- @param num number
--- @return string
local function repeat_text(text, num)
    local line = ""
    for _ = 1, num do
        line = line .. text
    end
    return line
end

--- Get day number at current cursor position
--- @return number|nil: Day number or nil if not on a valid day
local function get_day_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1

    if row < 4 then
        return nil
    end

    local day = vim.fn.expand("<cword>")
    return tonumber(day)
end

--- Construct daily note filename from date
--- @param year number: Year
--- @param month number: Month (1-12)
--- @param day number: Day (1-31)
--- @return string: Filename in format "yyyy-mm-dd.md"
local function daily_note_filename(year, month, day)
    return string.format("%04d-%02d-%02d.md", year, month, day)
end

--- Validate and expand daily notes directory path
--- @param dir string: Directory path (may contain ~)
--- @return string|nil, string|nil: Expanded path or nil, error message or nil
local function validate_daily_notes_dir(dir)
    local expanded = vim.fn.expand(dir)

    if vim.fn.isdirectory(expanded) == 0 then
        return nil, string.format("Daily notes directory does not exist: %s", expanded)
    end

    return expanded, nil
end

--- Generate calendar content for a specific month
--- @param year number: The year to display
--- @param month number: The month to display (1-12)
--- @param highlight_day number|nil: Optional day to highlight (or nil for no highlight)
--- @return string[]: Array of text lines for the calendar
local function generate_calendar_content(year, month, highlight_day)
    -- Calculate calendar parameters
    local days = days_in_month(year, month)
    local first_weekday = first_day_of_month(year, month)
    local month_str = month_name(month)

    -- Build content array
    local content = {}

    table.insert(content, "")
    local header_month = string.format("│         %s %d", month_str, year)
    local header = header_month .. repeat_text(" ", 32 - string.len(header_month)) .. " │"
    table.insert(content, header)
    table.insert(
        content,
        "│ ──────────────────────────── │"
    )
    table.insert(content, "│  Mo  Tu  We  Th  Fr  Sa  Su  │")

    -- Calendar grid
    local line = "│ "
    local line_end = " │"
    local day = 1

    -- Add empty cells before first day (4 chars each: space + 2-char number + space)
    line = line .. repeat_text(" ", (first_weekday - 1) * 4)

    -- Add days
    local current_weekday = first_weekday
    while day <= days do
        -- Format day: space + 2-char number + space, or brackets for highlighted day
        local day_str
        if highlight_day and day == highlight_day then
            -- Highlighted day: brackets replace the spaces [12] or [ 2]
            day_str = "[" .. string.format("%2d", day) .. "]"
        else
            -- Normal: space + 2-char number + space
            day_str = " " .. string.format("%2d", day) .. " "
        end

        line = line .. day_str

        -- End of week or end of month
        if current_weekday == 7 or day == days then
            -- Pad rest of week if needed (4 chars per empty cell)
            if current_weekday < 7 then
                for _ = current_weekday + 1, 7 do
                    line = line .. "    "
                end
            end
            table.insert(content, line .. line_end)
            line = "│ "
            current_weekday = 1
        else
            current_weekday = current_weekday + 1
        end

        day = day + 1
    end

    table.insert(content, "")
    table.insert(content, "q: close  t: today  p: previous month  n: next month  Enter: open note")

    return content
end

--- Refresh buffer content with new calendar data
--- @param buf number: Buffer handle
local function refresh_buffer(buf)
    local year, month, highlight_day = get_buffer_state(buf)
    local content = generate_calendar_content(year, month, highlight_day)

    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

--- Navigate to today
--- @param buf number: Buffer handle
local function navigate_today(buf)
    local today = os.date("*t")
    set_buffer_state(buf, today.year, today.month, today.day)
    refresh_buffer(buf)
end

--- Navigate to next month
--- @param buf number: Buffer handle
local function navigate_next_month(buf)
    local year, month, _ = get_buffer_state(buf)
    local new_year, new_month = next_month(year, month)

    local today = os.date("*t")
    local new_highlight = (new_year == today.year and new_month == today.month) and today.day or nil

    set_buffer_state(buf, new_year, new_month, new_highlight)
    refresh_buffer(buf)
end

--- Navigate to previous month
--- @param buf number: Buffer handle
local function navigate_prev_month(buf)
    local year, month, _ = get_buffer_state(buf)
    local new_year, new_month = prev_month(year, month)

    local today = os.date("*t")
    local new_highlight = (new_year == today.year and new_month == today.month) and today.day or nil

    set_buffer_state(buf, new_year, new_month, new_highlight)
    refresh_buffer(buf)
end

--- Open daily note for the day at cursor position
--- @param buf number: Buffer handle
--- @param origin_win number: Original window to open note in
--- @param config table: Plugin configuration
local function open_daily_note(buf, origin_win, config)
    local day = get_day_at_cursor(buf)

    if not day then
        vim.notify("Cursor is not on a valid day", vim.log.levels.WARN)
        return
    end

    local year, month, _ = get_buffer_state(buf)
    local filename = daily_note_filename(year, month, day)

    local daily_notes_dir, err = validate_daily_notes_dir(config.daily_notes_dir)
    if not daily_notes_dir then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end

    local dir = daily_notes_dir:gsub("/$", "")
    local filepath = dir .. "/" .. filename

    vim.api.nvim_set_current_win(origin_win)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    vim.api.nvim_win_close(vim.fn.bufwinid(buf), false)
end

-- Show the calendar view in a new buffer
function M.show()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
    vim.api.nvim_set_option_value("filetype", "obsidian-calendar", { buf = buf })

    -- Initialize buffer state with current month
    local today = os.date("*t")
    set_buffer_state(buf, today.year, today.month, today.day)

    -- Generate and set content
    local content = generate_calendar_content(today.year, today.month, today.day)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    -- Capture original window before creating split
    local origin_win = vim.api.nvim_get_current_win()

    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    -- Set buffer-local keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", {
        noremap = true,
        silent = true,
        desc = "Close calendar view",
    })

    -- Navigation keymaps with Lua callbacks
    vim.keymap.set("n", "t", function()
        navigate_today(buf)
    end, {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Today",
    })

    vim.keymap.set("n", "n", function()
        navigate_next_month(buf)
    end, {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Next month",
    })

    vim.keymap.set("n", "p", function()
        navigate_prev_month(buf)
    end, {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Previous month",
    })

    vim.keymap.set("n", "<CR>", function()
        local main_config = require("obsidian-calendar").config
        open_daily_note(buf, origin_win, main_config)
    end, {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Open daily note",
    })
end

return M
