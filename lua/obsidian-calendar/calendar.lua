local file_utils = require("obsidian-calendar.file_utils")
local date_utils = require("obsidian-calendar.date_utils").utils
local Date = require("obsidian-calendar.date_utils").Date
local MonthDate = require("obsidian-calendar.date_utils").MonthDate
local view = require("obsidian-calendar.view")

local M = {}
local ns_id = vim.api.nvim_create_namespace("obsidian_calendar_highlights")

--- Get current displayed month/year from buffer state
--- @param buf number: Buffer handle
--- @return MonthDate, Date, boolean: month_date, today, preview_mode_active, notified_missing_dates
local function get_buffer_state(buf)
    local month_date = vim.api.nvim_buf_get_var(buf, "month_date")
    local today = vim.api.nvim_buf_get_var(buf, "today")
    local preview_active = vim.api.nvim_buf_get_var(buf, "preview_mode_active")

    return MonthDate.new(month_date.year, month_date.month),
        Date.new(today.year, today.month, today.day),
        preview_active
end

--- @param buf number: Buffer handle
--- @param month_date MonthDate
--- @param today Date
--- @param preview_mode_active boolean: Optional preview mode state
local function set_buffer_state(buf, month_date, today, preview_mode_active)
    vim.api.nvim_buf_set_var(buf, "month_date", month_date)
    vim.api.nvim_buf_set_var(buf, "today", today)
    vim.api.nvim_buf_set_var(buf, "preview_mode_active", preview_mode_active)
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

--- Opens daily note file in origin window for preview
--- @param origin_win number: Window handle
--- @param filepath string: Path to the daily note file
local function display_preview_content(origin_win, filepath)
    if not vim.api.nvim_win_is_valid(origin_win) then
        return
    end

    local current_win = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(origin_win)
    vim.api.nvim_win_call(origin_win, function()
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        vim.cmd("doautocmd BufRead")
    end)

    vim.api.nvim_set_current_win(current_win)
end

--- Updates preview window with note content for date at cursor
--- @param calendar_buf number: Calendar buffer handle
--- @param origin_win number: Original window to display preview in
--- @param daily_notes_dir string: Directory containing daily notes
local function update_preview(calendar_buf, origin_win, daily_notes_dir)
    local month_date, _, preview_active, _ = get_buffer_state(calendar_buf)

    if not preview_active then
        return
    end

    local day = get_day_at_cursor()
    if not day then
        return
    end

    local date = month_date:to_date(day)
    local filepath = file_utils.daily_note_path(date, daily_notes_dir)

    if file_utils.file_exists(filepath) then
        display_preview_content(origin_win, filepath)
    else
        vim.notify(string.format("No note exists for %s", date:to_text()), vim.log.levels.INFO)
    end
end

--- Toggles preview mode on/off
--- @param calendar_buf number: Calendar buffer handle
--- @param origin_win number: Original window handle
--- @param daily_notes_dir string: Daily notes directory
local function toggle_preview_mode(calendar_buf, origin_win, daily_notes_dir)
    local _, _, preview_active = get_buffer_state(calendar_buf)

    if preview_active then
        vim.api.nvim_buf_set_var(calendar_buf, "preview_mode_active", false)
        vim.api.nvim_clear_autocmds({ buffer = calendar_buf, group = "ObsidianCalendarPreview" })
        vim.notify("Preview mode disabled", vim.log.levels.INFO)
    else
        vim.api.nvim_buf_set_var(calendar_buf, "preview_mode_active", true)
        vim.api.nvim_buf_set_var(calendar_buf, "notified_missing_dates", {})

        local augroup = vim.api.nvim_create_augroup("ObsidianCalendarPreview", { clear = true })
        vim.api.nvim_create_autocmd("CursorMoved", {
            group = augroup,
            buffer = calendar_buf,
            callback = function()
                update_preview(calendar_buf, origin_win, daily_notes_dir)
            end,
        })

        vim.notify("Preview mode enabled - move cursor to preview notes", vim.log.levels.INFO)
        update_preview(calendar_buf, origin_win, daily_notes_dir)
    end
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
    local weekdays_hl = vim.api.nvim_get_hl(0, { name = config.highlights.weekdays })
    vim.api.nvim_set_hl(0, "WeekendDayNames", vim.tbl_extend("force", weekdays_hl, { underline = true }))
end

--- Apply extmarks to buffer
--- @param buf number: Buffer handle
--- @param extmarks table[]: Extmark specifications from LineBuilder
local function apply_extmarks(buf, extmarks)
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

    for _, mark in ipairs(extmarks) do
        vim.api.nvim_buf_set_extmark(buf, ns_id, mark.row, mark.start_col, {
            end_col = mark.end_col,
            hl_group = mark.hl_group,
        })
    end
end

--- Find cursor position for today's date by searching for bracket marker
--- @param buf number: Buffer handle
--- @return number, number: Row (1-indexed) and column (0-indexed)
local function calculate_today_cursor_position(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    for i, line in ipairs(lines) do
        local col = line:find("%[")
        if col then
            return i, col
        end
    end

    return 5, 2
end

--- Generate calendar content for a specific month
--- @param month_date MonthDate: The month to display
--- @param today Date: Day to highlight
--- @return string[], table[]: Array of text lines and extmark specifications
local function generate_calendar_content(month_date, today, daily_notes_dir)
    local calendar = view.Calendar.new(month_date, today, daily_notes_dir)
    return calendar:render()
end

--- Refresh buffer content with new calendar data
--- @param buf number: Buffer handle
--- @param daily_notes_dir string: Directory path (may contain ~)
local function refresh_buffer(buf, daily_notes_dir)
    local month_date, today = get_buffer_state(buf)
    local content, extmarks = generate_calendar_content(month_date, today, daily_notes_dir)

    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    apply_extmarks(buf, extmarks)
end

--- Navigate to today
--- @param buf number: Buffer handle
--- @param daily_notes_dir string: Directory path (may contain ~)
local function navigate_today(buf, daily_notes_dir)
    local _, today, preview_active = get_buffer_state(buf)
    set_buffer_state(buf, today:to_month_date(), today, preview_active)
    refresh_buffer(buf, daily_notes_dir)

    -- Position cursor on today's date
    local row, col = calculate_today_cursor_position(buf)
    vim.api.nvim_win_set_cursor(0, { row, col })
end

--- Navigate to next month
--- @param buf number: Buffer handle
--- @param daily_notes_dir string: Directory path (may contain ~)
local function navigate_next_month(buf, daily_notes_dir)
    local month_date, today, preview_active = get_buffer_state(buf)
    set_buffer_state(buf, month_date:next_month(), today, preview_active)
    refresh_buffer(buf, daily_notes_dir)
end

--- Navigate to previous month
--- @param buf number: Buffer handle
--- @param daily_notes_dir string: Directory path (may contain ~)
local function navigate_prev_month(buf, daily_notes_dir)
    local month_date, today, preview_active = get_buffer_state(buf)
    set_buffer_state(buf, month_date:prev_month(), today, preview_active)
    refresh_buffer(buf, daily_notes_dir)
end

--- Open daily note using direct file editing
--- @param filepath string: Full path to daily note file
--- @param origin_win number: Window to open note in
--- @param calendar_buf number: Calendar buffer
--- @param close_calendar boolean: Close calendar buffer and focus open note
local function open_note_direct(filepath, origin_win, calendar_buf, close_calendar)
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(origin_win)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    if close_calendar then
        vim.api.nvim_win_close(vim.fn.bufwinid(calendar_buf), false)
    else
        vim.api.nvim_set_current_win(current_win)
    end
end

--- Open daily note using obsidian.nvim command
--- @param offset number: Day offset from today
--- @param origin_win number: Window to open note in
--- @param calendar_buf number: Calendar buffer to close
--- @param close_calendar boolean: Close calendar buffer and focus open note
local function open_note_obsidian(offset, origin_win, calendar_buf, close_calendar)
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(origin_win)

    if vim.fn.exists(":ObsidianToday") == 0 then
        local ok = pcall(function()
            require("lazy").load({ plugins = { "obsidian.nvim" } })
        end)

        if not ok then
            vim.notify("Could not load obsidian.nvim plugin", vim.log.levels.WARN)
        end
    end

    local success, err = pcall(function()
        vim.cmd(string.format(":ObsidianToday %d", offset))
    end)

    if not success then
        vim.notify("Failed to open daily note: " .. tostring(err), vim.log.levels.ERROR)
    end

    if close_calendar then
        vim.api.nvim_win_close(vim.fn.bufwinid(calendar_buf), false)
    else
        vim.api.nvim_set_current_win(current_win)
    end
end

--- Open daily note for the day at cursor position
--- @param buf number: Buffer handle
--- @param origin_win number: Original window to open note in
--- @param daily_notes_dir string: Directory path (may contain ~)
--- @param close_calendar boolean: Close calendar buffer and focus open note
local function open_daily_note(buf, origin_win, daily_notes_dir, close_calendar)
    local day = get_day_at_cursor()

    if not day then
        vim.notify("Cursor is not on a valid day", vim.log.levels.WARN)
        return
    end

    local month_date, today = get_buffer_state(buf)
    local selected_date = month_date:to_date(day)
    local filepath = file_utils.daily_note_path(selected_date, daily_notes_dir)

    if file_utils.file_exists(filepath) then
        open_note_direct(filepath, origin_win, buf, close_calendar)
        return
    end

    if require("obsidian-calendar").config.obsidian.enabled then
        local offset = date_utils.day_offset(today, selected_date)
        open_note_obsidian(offset, origin_win, buf, close_calendar)
    else
        open_note_direct(filepath, origin_win, buf, close_calendar)
    end
end

--- Find existing calendar buffer if it exists
--- @return number|nil: Buffer handle or nil if not found
local function find_existing_calendar_buffer()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
            if filetype == "obsidian-calendar" then
                return buf
            end
        end
    end
    return nil
end

--- Find window displaying a specific buffer
--- @param buf number: Buffer handle
--- @return number|nil: Window handle or nil if not found
local function find_buffer_window(buf)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
            return win
        end
    end
    return nil
end

-- Show the calendar view in a new buffer
function M.show()
    -- Check if calendar is already open
    local existing_buf = find_existing_calendar_buffer()
    if existing_buf then
        local existing_win = find_buffer_window(existing_buf)
        if existing_win then
            vim.api.nvim_set_current_win(existing_win)
            return
        end
    end

    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
    vim.api.nvim_set_option_value("filetype", "obsidian-calendar", { buf = buf })

    -- Initialize buffer state with current month
    local today = date_utils.get_today_date()
    local month_date = today:to_month_date()
    set_buffer_state(buf, month_date, today, false)

    -- Initialize highlight groups
    local main_config = require("obsidian-calendar").config
    init_highlights(main_config)

    -- Generate and set content
    local content, extmarks = generate_calendar_content(month_date, today, main_config.daily_notes_dir)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    -- Apply highlights
    apply_extmarks(buf, extmarks)

    -- Capture original window before creating split
    local origin_win = vim.api.nvim_get_current_win()

    -- Open the buffer in a new window
    vim.api.nvim_command("split")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_height(win, 15)

    -- Position cursor on today's date
    local row, col = calculate_today_cursor_position(buf)
    vim.api.nvim_win_set_cursor(win, { row, col })

    -- Set buffer-local keymaps
    vim.api.nvim_buf_set_keymap(
        buf,
        "n",
        "q",
        ":q<CR>",
        { noremap = true, silent = true, desc = "Close calendar view" }
    )

    -- Navigation keymaps with Lua callbacks
    vim.keymap.set("n", "t", function()
        navigate_today(buf, main_config.daily_notes_dir)
    end, { buffer = buf, noremap = true, silent = true, desc = "Today" })

    vim.keymap.set("n", "n", function()
        navigate_next_month(buf, main_config.daily_notes_dir)
    end, { buffer = buf, noremap = true, silent = true, desc = "Next month" })

    vim.keymap.set("n", "p", function()
        navigate_prev_month(buf, main_config.daily_notes_dir)
    end, { buffer = buf, noremap = true, silent = true, desc = "Previous month" })

    vim.keymap.set("n", "o", function()
        open_daily_note(buf, origin_win, main_config.daily_notes_dir, true)
    end, { buffer = buf, noremap = true, silent = true, desc = "Open daily note" })

    vim.keymap.set("n", "O", function()
        open_daily_note(buf, origin_win, main_config.daily_notes_dir, false)
    end, { buffer = buf, noremap = true, silent = true, desc = "Open daily note" })

    vim.keymap.set("n", "P", function()
        toggle_preview_mode(buf, origin_win, main_config.daily_notes_dir)
    end, { buffer = buf, noremap = true, silent = true, desc = "Toggle preview mode" })
end

return M
