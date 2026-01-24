-- Calendar rendering and display logic

local M = {}
local ns_id = vim.api.nvim_create_namespace("obsidian_calendar_highlights")

--- @class MonthDate
--- @field year number: The year (e.g., 2024)
--- @field month number: The month (1-12)

--- @class Date
--- @field year number: The year (e.g., 2024)
--- @field month number: The month (1-12)
--- @field day number: The day (1-31)

--- @return Date
local function get_today_date()
    local today = os.date("*t")
    return { year = today.year, month = today.month, day = today.day }
end

--- @param date Date
--- @return MonthDate
local function to_month_date(date)
    return { year = date.year, month = date.month }
end

--- Check if year is a leap year
--- @param year number: The year to check
--- @return boolean: True if leap year
local function is_leap_year(year)
    return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

--- Get number of days in a month
--- @param date MonthDate: The month to check
--- @return number: Days in the month (28-31)
local function days_in_month(date)
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if date.month == 2 and is_leap_year(date.year) then
        return 29
    end
    return days[date.month]
end

--- Get first day of month as weekday number
--- @param date MonthDate: The month to check
--- @return number: Day of week (1=Monday, 7=Sunday)
local function first_day_of_month(date)
    local time = os.time({ year = date.year, month = date.month, day = 1 })
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
--- @param date MonthDate: Current month
--- @return MonthDate: Next month
local function next_month(date)
    if date.month == 12 then
        return { year = date.year + 1, month = 1 }
    end
    return { year = date.year, month = date.month + 1 }
end

--- Navigate to previous month
--- @param date MonthDate: Current month
--- @return MonthDate: Previous month
local function prev_month(date)
    if date.month == 1 then
        return { year = date.year - 1, month = 12 }
    end
    return { year = date.year, month = date.month - 1 }
end

--- Get current displayed month/year from buffer state
--- @param buf number: Buffer handle
--- @return MonthDate, Date: month_date, today
local function get_buffer_state(buf)
    local month_date = vim.api.nvim_buf_get_var(buf, "month_date")
    local today = vim.api.nvim_buf_get_var(buf, "today")
    return month_date, today
end

--- @param buf number: Buffer handle
--- @param month_date MonthDate
--- @param today Date
local function set_buffer_state(buf, month_date, today)
    vim.api.nvim_buf_set_var(buf, "month_date", month_date)
    vim.api.nvim_buf_set_var(buf, "today", today)
end

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
--- @param date Date: The date
--- @return string: Filename in format "yyyy-mm-dd.md"
local function daily_note_filename(date)
    return string.format("%04d-%02d-%02d.md", date.year, date.month, date.day)
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

--- Initialize highlight groups for calendar
--- @param config table: Configuration with highlight group mappings
local function init_highlights(config)
    local highlight_groups = {
        ObsidianCalendarBorder = config.highlights.border,
        ObsidianCalendarHeader = config.highlights.header,
        ObsidianCalendarWeekdays = config.highlights.weekdays,
        ObsidianCalendarToday = config.highlights.today,
        ObsidianCalendarDay = config.highlights.day,
        ObsidianCalendarWeekend = config.highlights.weekend,
        ObsidianCalendarSeparator = config.highlights.separator,
        ObsidianCalendarHelp = config.highlights.help,
    }

    for group_name, link_to in pairs(highlight_groups) do
        vim.api.nvim_set_hl(0, group_name, { link = link_to, default = true })
    end
end

--- Highlight border characters in a line
--- @param buf number: Buffer handle
--- @param line string: The line content
--- @param row number: Row index (0-based)
local function highlight_borders(buf, line, row)
    local col = 0
    while true do
        local start_col = line:find("│", col + 1, true)
        if not start_col then
            break
        end
        vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col - 1, {
            end_col = start_col,
            hl_group = "ObsidianCalendarBorder",
        })
        col = start_col
    end
end

--- Highlight month/year header
--- @param buf number: Buffer handle
--- @param line string: The line content
--- @param row number: Row index (0-based)
local function highlight_header(buf, line, row)
    highlight_borders(buf, line, row)

    local first_border = line:find("│", 1, true)
    local last_border = line:find("│[^│]*$")

    if first_border and last_border then
        vim.api.nvim_buf_set_extmark(buf, ns_id, row, first_border, {
            end_col = last_border - 1,
            hl_group = "ObsidianCalendarHeader",
        })
    end
end

--- Highlight separator line
--- @param buf number: Buffer handle
--- @param line string: The line content
--- @param row number: Row index (0-based)
local function highlight_separator(buf, line, row)
    highlight_borders(buf, line, row)

    local start_col = line:find("─", 1, true)
    if start_col then
        local end_col = line:find(" │$")
        if end_col then
            vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col - 1, {
                end_col = end_col - 1,
                hl_group = "ObsidianCalendarSeparator",
            })
        end
    end
end

--- Highlight weekday labels
--- @param buf number: Buffer handle
--- @param line string: The line content
--- @param row number: Row index (0-based)
local function highlight_weekdays(buf, line, row)
    highlight_borders(buf, line, row)

    local first_border = line:find("│", 1, true)
    local last_border = line:find("│[^│]*$")

    if first_border and last_border then
        vim.api.nvim_buf_set_extmark(buf, ns_id, row, first_border, {
            end_col = last_border - 1,
            hl_group = "ObsidianCalendarWeekdays",
        })
    end
end

--- Highlight calendar row with days
--- @param buf number: Buffer handle
--- @param line string: The line content
--- @param row number: Row index (0-based)
--- @param month_date MonthDate: Current displayed month
--- @param today Date: Today's date
--- @param first_weekday number: First weekday of the month (1=Monday, 7=Sunday)
local function highlight_calendar_row(buf, line, row, month_date, today, first_weekday)
    highlight_borders(buf, line, row)

    local col = 0
    while true do
        local start_col, end_col, day_str = line:find("%[(%d+)%]", col + 1)
        if not start_col then
            break
        end
        vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col - 1, {
            end_col = end_col,
            hl_group = "ObsidianCalendarToday",
            priority = 200,
        })
        col = end_col
    end

    col = 0
    while true do
        local start_col, end_col, day_str = line:find(" (%d+) ", col + 1)
        if not start_col then
            break
        end

        local day = tonumber(day_str)
        if day then
            local weekday = (first_weekday + day - 2) % 7 + 1

            local hl_group = "ObsidianCalendarDay"
            if weekday == 6 or weekday == 7 then
                hl_group = "ObsidianCalendarWeekend"
            end

            vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col, {
                end_col = end_col - 1,
                hl_group = hl_group,
            })
        end
        col = end_col
    end
end

--- Highlight help text
--- @param buf number: Buffer handle
--- @param line string: The line content
--- @param row number: Row index (0-based)
local function highlight_help(buf, line, row)
    vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
        end_col = #line,
        hl_group = "ObsidianCalendarHelp",
    })
end

--- Apply highlights to calendar buffer using extmarks
--- @param buf number: Buffer handle
--- @param month_date MonthDate: The displayed month
--- @param today Date: Today's date for highlighting
local function apply_highlights(buf, month_date, today)
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local line_count = #lines

    if line_count < 5 then
        return
    end

    local first_weekday = first_day_of_month(month_date)

    highlight_header(buf, lines[2], 1)
    highlight_separator(buf, lines[3], 2)
    highlight_weekdays(buf, lines[4], 3)

    for row = 4, line_count - 3 do
        if lines[row + 1] then
            highlight_calendar_row(buf, lines[row + 1], row, month_date, today, first_weekday)
        end
    end

    if lines[line_count] then
        highlight_help(buf, lines[line_count], line_count - 1)
    end
end

--- Generate calendar content for a specific month
--- @param month_date MonthDate: The month to display
--- @param today Date: Optional day to highlight (or nil for no highlight)
--- @return string[]: Array of text lines for the calendar
local function generate_calendar_content(month_date, today)
    -- Calculate calendar parameters
    local days = days_in_month(month_date)
    local first_weekday = first_day_of_month(month_date)
    local month_str = month_name(month_date.month)

    -- Build content array
    local content = {}

    table.insert(content, "")
    local header_month = string.format("│         %s %d", month_str, month_date.year)
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
        if month_date == to_month_date(today) and day == today.day then
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
    local month_date, today = get_buffer_state(buf)
    local content = generate_calendar_content(month_date, today)

    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    apply_highlights(buf, month_date, today)
end

--- Navigate to today
--- @param buf number: Buffer handle
local function navigate_today(buf)
    local _, today = get_buffer_state(buf)
    set_buffer_state(buf, to_month_date(today), today)
    refresh_buffer(buf)
end

--- Navigate to next month
--- @param buf number: Buffer handle
local function navigate_next_month(buf)
    local month_date, today = get_buffer_state(buf)
    set_buffer_state(buf, next_month(month_date), today)
    refresh_buffer(buf)
end

--- Navigate to previous month
--- @param buf number: Buffer handle
local function navigate_prev_month(buf)
    local month_date, today = get_buffer_state(buf)
    set_buffer_state(buf, prev_month(month_date), today)
    refresh_buffer(buf)
end

--- Open daily note for the day at cursor position
--- @param buf number: Buffer handle
--- @param origin_win number: Original window to open note in
--- @param config table: Plugin configuration
local function open_daily_note(buf, origin_win, config)
    local day = get_day_at_cursor()

    if not day then
        vim.notify("Cursor is not on a valid day", vim.log.levels.WARN)
        return
    end

    local month_date, _ = get_buffer_state(buf)
    local full_date = { year = month_date.year, month = month_date.month, day = day }
    local filename = daily_note_filename(full_date)

    local daily_notes_dir, err = validate_daily_notes_dir(config.daily_notes_dir)
    if not daily_notes_dir then
        vim.notify(err or "Invalid diretory", vim.log.levels.ERROR)
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
    local today = get_today_date()
    local month_date = { year = today.year, month = today.month }
    set_buffer_state(buf, month_date, today)

    -- Initialize highlight groups
    local main_config = require("obsidian-calendar").config
    init_highlights(main_config)

    -- Generate and set content
    local content = generate_calendar_content(month_date, today)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    -- Apply highlights
    apply_highlights(buf, month_date, today)

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
