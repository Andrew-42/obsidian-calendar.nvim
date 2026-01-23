# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Neovim plugin for viewing a calendar of daily notes in Obsidian-style markdown vaults. Currently displays a calendar view with the current month highlighted.

## Architecture

The plugin follows a functional, composition-based architecture with three main components:

1. **plugin/obsidian-calendar.lua** - Plugin entry point, auto-loaded by Neovim. Defines the `:ObsidianCalendar` command.
2. **lua/obsidian-calendar/init.lua** - Module interface providing `setup()` and `open()` functions.
3. **lua/obsidian-calendar/calendar.lua** - Calendar rendering logic with pure helper functions for date calculations and UI generation.

### Design Principles (from AGENTS.md)

1. **Functional Composition**: Build complex behavior from simple, composable functions
2. **Type Documentation**: Use LuaLS docstrings (`---`) for type information, not inline annotations
3. **Minimal Comments**: Code should be self-documenting; avoid redundant explanations
4. **Short Functions**: Break logic into small, single-purpose functions that compose
5. **Pure Functions**: Prefer functions without side effects; isolate I/O and state changes

### Code Style

```lua
--- Calculates days in a given month
--- @param year number: The year (e.g., 2024)
--- @param month number: The month (1-12)
--- @return number: Days in the month (28-31)
local function days_in_month(year, month)
  -- Implementation
end
```

## Development

### Testing in Neovim

Load the plugin locally by adding to your Neovim config:

```lua
{
  dir = '/Users/ondrejhlavacka/Personal/0_Code/lua/obsidian-calendar',
  config = function()
    require('obsidian-calendar').setup({
      -- Configuration options
    })
  end
}
```

Test with `:ObsidianCalendar` command. Press `q` to close the calendar view.

### File Structure

```
plugin/obsidian-calendar.lua     -- Command registration (auto-loaded)
lua/obsidian-calendar/
  init.lua                        -- Module entry point
  calendar.lua                    -- Calendar rendering logic
```

## Current Status

- Basic calendar view displays current month with today highlighted
- Next planned features (see README.md):
  - Add signs for notes on specific days
  - Add diagnostic signs
