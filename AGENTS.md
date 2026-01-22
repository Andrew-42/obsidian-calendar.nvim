# Agent Architecture

## Overview

This document describes the agent-based architecture of the obsidian-calendar Neovim plugin. The design emphasizes **functional composition**, **pure functions**, and **minimal coupling** between components.

## Design Philosophy

### Core Principles

1. **Functional Composition**: Build complex behavior from simple, composable functions
2. **Type Documentation**: Use docstrings (`---`) for type information, not inline annotations
3. **Minimal Comments**: Code should be self-documenting; avoid redundant explanations
4. **Short Functions**: Break logic into small, single-purpose functions that compose
5. **Pure Functions**: Prefer functions without side effects; isolate I/O and state changes

### Code Style Example

```lua
--- Calculates days in a given month
--- @param year number: The year (e.g., 2024)
--- @param month number: The month (1-12)
--- @return number: Days in the month (28-31)
local function days_in_month(year, month)
  local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if month == 2 and is_leap_year(year) then
    return 29
  end
  return days[month]
end

--- Checks if a year is a leap year
--- @param year number: The year to check
--- @return boolean: True if leap year
local function is_leap_year(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end
```

## References

- [Neovim Lua Guide](https://neovim.io/doc/user/lua.html)
- [LuaLS Annotations](https://github.com/LuaLS/lua-language-server/wiki/Annotations)
- [Functional Programming in Lua](https://www.lua.org/pil/6.1.html)
