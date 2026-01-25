# Obsidian Calendar

A Neovim plugin for viewing a calendar of your daily notes in Obsidian-style markdown vaults.

## Features

- [x] Display monthly calendar view with navigation
- [x] Theme-aware color highlighting
- [x] Weekend highlighting
- [x] Today's date indication
- [x] Open daily notes from calendar
- [x] Add signs for existing notes
- [ ] Add diagnostic signs

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  dir = '/path/to/obsidian-calendar',  -- Update with your local path
  config = function()
    require('obsidian-calendar').setup({
      daily_notes_dir = "~/path/to/your/daily-notes/",
    })
  end
}
```

## Usage

### Commands

- `:ObsidianCalendar` - Open the calendar view

### Keymaps

When in the calendar view:
- `q` - Close the calendar buffer
- `t` - Navigate to today's date
- `n` - Navigate to next month
- `p` - Navigate to previous month
- `Enter` - Open daily note for the day under cursor

## Configuration

The plugin can be configured with the following options:

```lua
require('obsidian-calendar').setup({
  -- Directory containing your daily notes
  daily_notes_dir = "~/Personal/2_Areas/0_obsidian-notes/Daily Logs/",

  -- Highlight group mappings (all optional, defaults shown)
  highlights = {
    border = "FloatBorder",      -- Box-drawing border characters
    header = "Title",             -- Month and year header
    weekdays = "Comment",         -- Weekday labels (Mo Tu We...)
    today = "Special",            -- Today's date (shown in brackets)
    day = "Normal",               -- Regular day numbers (Mon-Fri)
    weekend = "Comment",          -- Weekend day numbers (Sat-Sun)
    separator = "Comment",        -- Separator line
    help = "Comment",             -- Help text at bottom
  },
})
```

### Highlight Customization

The calendar uses theme-aware colors by linking to standard Neovim highlight groups. This means it automatically adapts to your colorscheme.

#### Using Different Built-in Groups

You can customize which highlight groups are used:

```lua
require('obsidian-calendar').setup({
  highlights = {
    today = "IncSearch",       -- Use search highlight for today
    header = "@text.title",    -- Use treesitter group for header
    weekend = "Comment",       -- Keep weekends subtle
  },
})
```

#### Using Custom Colors

For full control, define your own highlight groups first, then link to them:

```lua
-- Define custom highlight groups with your preferred colors
vim.api.nvim_set_hl(0, "MyCalendarToday", { fg = "#FF6B6B", bold = true })
vim.api.nvim_set_hl(0, "MyCalendarWeekend", { fg = "#87CEEB" })

-- Link to them in setup
require('obsidian-calendar').setup({
  highlights = {
    today = "MyCalendarToday",
    weekend = "MyCalendarWeekend",
  },
})
```

## Development Status

The plugin currently provides:
- Full calendar view with month/year navigation
- Theme-aware syntax highlighting that adapts to your colorscheme
- Weekend day highlighting for better visual organization
- Daily note creation and opening directly from the calendar
- Customizable color scheme through highlight group mappings

Future features include diagnostic indicators.

## License

TBD
