---@class DateUtils
---@field utils date_utils
---@field Date Date
---@field MonthDate MonthDate

--- @class date_utils
local M = {}

--- @class Date
--- @field year number: The year (e.g., 2024)
--- @field month number: The month (1-12)
--- @field day number: The day (1-31)
--- @field new fun(year:number, month:number, day:number): Date
local Date = {}
Date.__index = Date

--- @class MonthDate
--- @field year number: The year (e.g., 2024)
--- @field month number: The month (1-12)
--- @field new fun(year:number, month:number): MonthDate
local MonthDate = {}
MonthDate.__index = MonthDate

--- Check if year is a leap year
--- @param year number: The year to check
--- @return boolean: True if leap year
function M.is_leap_year(year)
    return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

--- Get month name
--- @param month number: The month (1-12)
--- @return string: Month name
function M.month_name(month)
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

--- @param year number
--- @param month number
--- @param day number
--- @return Date
function Date.new(year, month, day)
    return setmetatable({ year = year, month = month, day = day }, Date)
end

--- @param date Date
function Date:__eq(date)
    return self.year == date.year and self.month == date.month and self.day == date.day
end

--- @param year number
--- @param month number
--- @return MonthDate
function MonthDate.new(year, month)
    return setmetatable({ year = year, month = month }, MonthDate)
end

--- @param month_date Date
function MonthDate:__eq(month_date)
    return self.year == month_date.year and self.month == month_date.month
end

--- @return Date
function M.get_today_date()
    local today = os.date("*t")
    return Date.new(today.year, today.month, today.day)
end

--- @return MonthDate
function Date:to_month_date()
    return MonthDate.new(self.year, self.month)
end

--- @param day number
--- @return Date
function MonthDate:to_date(day)
    return Date.new(self.year, self.month, day)
end
function MonthDate:to_text()
    local month_str = M.month_name(self.month)
    return string.format("%s %d", month_str, self.year)
end

--- Get number of days in a month
--- @return number: Days in the month (28-31)
function MonthDate:days_in_month()
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if self.month == 2 and M.is_leap_year(self.year) then
        return 29
    end
    return days[self.month]
end

--- Get first day of month as weekday number
--- @return number: Day of week (1=Monday, 7=Sunday)
function MonthDate:first_day_of_month()
    return self:to_date(1):day_of_week()
end

--- Get first day of month as weekday number
--- @return number: Day of week (1=Monday, 7=Sunday)
function Date:day_of_week()
    local time = os.time({ year = self.year, month = self.month, day = self.day })
    local wday = os.date("*t", time).wday
    -- Convert from Lua's Sunday=1 to Monday=1
    return wday == 1 and 7 or wday - 1
end

--- Navigate to next month
--- @return MonthDate: Next month
function MonthDate:next_month()
    if self.month == 12 then
        return MonthDate.new(self.year + 1, 1)
    end
    return MonthDate.new(self.year, self.month + 1)
end

--- Navigate to previous month
--- @return MonthDate: Previous month
function MonthDate:prev_month()
    if self.month == 1 then
        return MonthDate.new(self.year - 1, 12)
    end
    return MonthDate.new(self.year, self.month - 1)
end

--- Calculate day offset between two dates
--- @param from_date Date: Starting date (typically today)
--- @param to_date Date: Target date
--- @return number: Number of days offset (negative for past, positive for future)
function M.day_offset(from_date, to_date)
    local from_time = os.time({
        year = from_date.year,
        month = from_date.month,
        day = from_date.day,
        hour = 12,
    })
    local to_time = os.time({
        year = to_date.year,
        month = to_date.month,
        day = to_date.day,
        hour = 12,
    })
    return math.floor((to_time - from_time) / 86400)
end

---@type DateUtils
return { utils = M, Date = Date, MonthDate = MonthDate }
