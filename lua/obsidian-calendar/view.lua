local file_utils = require("obsidian-calendar.file_utils")

--- @class LineBuilder
--- @field lines string[]: Accumulated lines
--- @field extmarks table[]: Accumulated extmark specifications
--- @field current_line string: Current line being built
--- @field current_row number: Current row (0-based)
local LineBuilder = {}
LineBuilder.__index = LineBuilder

function LineBuilder.new()
    return setmetatable({
        lines = {},
        extmarks = {},
        current_line = "",
        current_row = 0,
    }, LineBuilder)
end

--- Append text without highlighting
--- @param text string
--- @return LineBuilder: Self for chaining
function LineBuilder:append(text)
    self.current_line = self.current_line .. text
    return self
end

--- Append text with highlighting
--- @param text string|string[]
--- @param hl_group string: Highlight group name
--- @return LineBuilder: Self for chaining
function LineBuilder:append_hl(text, hl_group)
    local parts = type(text) == "table" and text or { text }

    for _, part in ipairs(parts) do
        local start_col = #self.current_line
        self.current_line = self.current_line .. part
        local end_col = #self.current_line

        table.insert(self.extmarks, {
            row = self.current_row,
            start_col = start_col,
            end_col = end_col,
            hl_group = hl_group,
        })
    end

    return self
end

--- Finish current line and move to next row
--- @return LineBuilder: Self for chaining
function LineBuilder:newline()
    table.insert(self.lines, self.current_line)
    self.current_line = ""
    self.current_row = self.current_row + 1
    return self
end

--- Get accumulated lines and extmarks
--- @return string[], table[]
function LineBuilder:build()
    if #self.current_line > 0 then
        self:newline()
    end
    return self.lines, self.extmarks
end

--- @class DayCell
--- @field date Date: The date (e.g. 2026-01-15)
--- @field weekday number: The week day number (1-7, Monday=1)
--- @field text string: The text cell (" 23 " | "[12]")
--- @field is_today boolean: Whether the date is today
--- @field has_note boolean: Whether a daily note exists for this date (future feature)
--- @field new fun(date:Date, today:Date, has_note:boolean): DayCell
local DayCell = {}
DayCell.__index = DayCell

--- @param char string
--- @param num number
--- @param text string
--- @return string
local function pad_left(char, num, text)
    local pad_len = num - #text
    return string.rep(char, pad_len) .. text
end

--- @param date Date
--- @param today Date
--- @param has_note boolean
--- @return DayCell
function DayCell.new(date, today, has_note)
    local is_today = date == today

    local text
    if is_today then
        text = pad_left(" ", 4, "[" .. date.day .. "]")
    else
        -- Future: when has_note is true, could use " 12·" or "*12 "
        local note_char
        if has_note then
            note_char = "x"
        else
            note_char = " "
        end
        text = pad_left(" ", 4, note_char .. date.day .. " "):gsub("x", "·", 1)
    end

    return setmetatable({
        date = date,
        weekday = date:day_of_week(),
        text = text,
        is_today = is_today,
        has_note = has_note,
    }, DayCell)
end

--- @return boolean
function DayCell:is_weekend()
    return self.weekday == 6 or self.weekday == 7
end

--- @class Calendar
--- @field month_date MonthDate
--- @field day_cells DayCell[]
--- @field border_start string
--- @field border_end string
--- @field new fun(month_date:MonthDate, today:Date, dir:string): Calendar
local Calendar = {}
Calendar.__index = Calendar

--- @param month_date MonthDate
--- @param today Date
--- @param dir string
--- @return Calendar
function Calendar.new(month_date, today, dir)
    local days = month_date:days_in_month()
    local cells = {}
    for day = 1, days do
        local date = month_date:to_date(day)
        local has_note = vim.fn.filereadable(file_utils.daily_note_path(date, dir)) == 1
        table.insert(cells, DayCell.new(date, today, has_note))
    end

    return setmetatable({
        month_date = month_date,
        day_cells = cells,
        border_start = "│ ",
        border_end = " │",
    }, Calendar)
end

--- @param builder LineBuilder
function Calendar:header(builder)
    local text = self.month_date:to_text()
    local padding_left = 8
    local total_width = 28
    local padding_right = total_width - padding_left - #text

    builder:append_hl(self.border_start, "ObsidianCalendarBorder")
    builder:append(string.rep(" ", padding_left))
    builder:append_hl(text, "ObsidianCalendarHeader")
    builder:append(string.rep(" ", padding_right))
    builder:append_hl(self.border_end, "ObsidianCalendarBorder")
    builder:newline()
end

--- @param builder LineBuilder
function Calendar:separator(builder)
    builder:append_hl(self.border_start, "ObsidianCalendarBorder")
    builder:append_hl(string.rep("─", 28), "ObsidianCalendarSeparator")
    builder:append_hl(self.border_end, "ObsidianCalendarBorder")
    builder:newline()
end

--- @param builder LineBuilder
function Calendar:weekdays(builder)
    builder:append_hl(self.border_start, "ObsidianCalendarBorder")
    builder:append_hl(" Mo  Tu  We  Th  Fr  ", "ObsidianCalendarWeekdays")
    builder:append_hl("Sa", "WeekendDayNames")
    builder:append("  ")
    builder:append_hl("Su", "WeekendDayNames")
    builder:append(" ")
    builder:append_hl(self.border_end, "ObsidianCalendarBorder")
    builder:newline()
end

--- @param builder LineBuilder
function Calendar:body(builder)
    local first_weekday = self.day_cells[1].weekday
    builder:append_hl(self.border_start, "ObsidianCalendarBorder")
    builder:append(string.rep(" ", (first_weekday - 1) * 4))

    local current_weekday = first_weekday
    for _, cell in ipairs(self.day_cells) do
        if cell.is_today then
            builder:append_hl(cell.text, "ObsidianCalendarToday")
        elseif cell:is_weekend() then
            builder:append_hl(cell.text, "ObsidianCalendarWeekend")
        elseif cell.date:is_czech_national_holiday() then
            builder:append_hl(cell.text, "ObsidianCalendarWeekend")
        else
            builder:append_hl(cell.text, "ObsidianCalendarDay")
        end

        if current_weekday == 7 or cell.date.day == #self.day_cells then
            if current_weekday < 7 then
                builder:append(string.rep(" ", (7 - current_weekday) * 4))
            end
            builder:append_hl(self.border_end, "ObsidianCalendarBorder")
            builder:newline()

            if cell.date.day ~= #self.day_cells then
                builder:append_hl(self.border_start, "ObsidianCalendarBorder")
            end
            current_weekday = 1
        else
            current_weekday = current_weekday + 1
        end
    end
end

--- @param builder LineBuilder
function Calendar:help(builder)
    builder:append_hl("q: close  t: today  p: previous month  n: next month  Enter: open note", "ObsidianCalendarHelp")
    builder:newline()
end

--- Render calendar with highlight specifications
--- @return string[], table[]
function Calendar:render()
    local builder = LineBuilder.new()

    builder:newline()
    self:header(builder)
    self:separator(builder)
    self:weekdays(builder)
    self:body(builder)
    builder:newline()
    self:help(builder)

    return builder:build()
end

local M = {}
M.Calendar = Calendar
M.DayCell = DayCell
return M
