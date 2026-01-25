--- @class DayCell
--- @field date Date: The date (e.g. 2026-01-15)
--- @field weekday number: The week day number (1-7, Monday=1)
--- @field text string: The text cell (" 23 " | "[12]")
--- @field has_note boolean: Whether a daily note exists for this date (future feature)
--- @field new fun(date:Date, today:Date, has_note:boolean|nil): DayCell
local DayCell = {}
DayCell.__index = DayCell

--- @param date Date
--- @param today Date
--- @param has_note boolean|nil
--- @return DayCell
function DayCell.new(date, today, has_note)
    local is_today = date.year == today.year and date.month == today.month and date.day == today.day

    local text
    if is_today then
        text = "[" .. string.format("%2d", date.day) .. "]"
    else
        -- Future: when has_note is true, could use " 12·" or "*12 "
        text = " " .. string.format("%2d", date.day) .. " "
    end

    return setmetatable({
        date = date,
        weekday = date:day_of_week(),
        text = text,
        has_note = has_note or false,
    }, DayCell)
end

--- @class Calendar
--- @field month_date MonthDate
--- @field day_cells DayCell[]
--- @field border_start string
--- @field border_end string
--- @field new fun(month_date:MonthDate, today:Date): Calendar
local Calendar = {}
Calendar.__index = Calendar

--- @param month_date MonthDate
--- @param today Date
--- @return Calendar
function Calendar.new(month_date, today)
    local days = month_date:days_in_month()
    local cells = {}
    for day = 1, days do
        table.insert(cells, DayCell.new(month_date:to_date(day), today, false))
    end

    return setmetatable({
        month_date = month_date,
        day_cells = cells,
        border_start = "│ ",
        border_end = " │",
    }, Calendar)
end

--- @return string
function Calendar:header()
    local text = self.month_date:to_text()
    local padding_left = 8
    local total_width = 28
    local padding_right = total_width - padding_left - #text

    return self.border_start
        .. string.rep(" ", padding_left)
        .. text
        .. string.rep(" ", padding_right)
        .. self.border_end
end

--- @return string
function Calendar:separator()
    return self.border_start .. string.rep("─", 28) .. self.border_end
end

--- @return string
function Calendar:weekdays()
    return self.border_start .. " Mo  Tu  We  Th  Fr  Sa  Su " .. self.border_end
end

--- @return string[]
function Calendar:body()
    local lines = {}
    local line = self.border_start
    local first_weekday = self.month_date:first_day_of_month()

    -- Add leading spaces for days before the first day of month
    line = line .. string.rep(" ", (first_weekday - 1) * 4)

    -- Add each day cell
    local current_weekday = first_weekday
    for _, cell in ipairs(self.day_cells) do
        line = line .. cell.text

        -- End of week or end of month
        if current_weekday == 7 or cell.date.day == #self.day_cells then
            -- Pad remaining days in the week
            if current_weekday < 7 then
                line = line .. string.rep(" ", (7 - current_weekday) * 4)
            end
            table.insert(lines, line .. self.border_end)
            line = self.border_start
            current_weekday = 1
        else
            current_weekday = current_weekday + 1
        end
    end

    return lines
end

--- @return string
function Calendar:help()
    return "q: close  t: today  p: previous month  n: next month  Enter: open note"
end

--- @return string[]
function Calendar:to_lines()
    local lines = {}

    table.insert(lines, "")
    table.insert(lines, self:header())
    table.insert(lines, self:separator())
    table.insert(lines, self:weekdays())

    for _, body_line in ipairs(self:body()) do
        table.insert(lines, body_line)
    end

    table.insert(lines, "")
    table.insert(lines, self:help())

    return lines
end

local M = {}
M.Calendar = Calendar
M.DayCell = DayCell
return M
