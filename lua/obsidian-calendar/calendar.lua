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

--- Generate calendar content for current month
--- @return string[]: Array of text lines for the calendar
local function generate_calendar_content()
    -- Get current date
    local today = os.date("*t")

    -- Calculate calendar parameters
    local days = days_in_month(today.year, today.month)
    local first_weekday = first_day_of_month(today.year, today.month)
    local month_str = month_name(today.month)

    -- Build content array
    local content = {}

    table.insert(content, "")
    local header = string.format("       %s %d", month_str, today.year)
    table.insert(content, header)
    table.insert(content, " ──────────────────────────── ")
    table.insert(content, "  Mo  Tu  We  Th  Fr  Sa  Su  ")

    -- Calendar grid
    local line = " "
    local day = 1

    -- Add empty cells before first day (4 chars each: space + 2-char number + space)
    for _ = 1, first_weekday - 1 do
        line = line .. "    "
    end

    -- Add days
    local current_weekday = first_weekday
    while day <= days do
        -- Format day: space + 2-char number + space, or brackets for today
        local day_str
        if day == today.day then
            -- Today: brackets replace the spaces [12] or [ 2]
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
                for i = current_weekday + 1, 7 do
                    line = line .. "    "
                end
            end
            table.insert(content, line)
            line = " "
            current_weekday = 1
        else
            current_weekday = current_weekday + 1
        end

        day = day + 1
    end

    table.insert(content, "")
    table.insert(content, "Press q to close")

    return content
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

    local content = generate_calendar_content()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

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
end

return M
