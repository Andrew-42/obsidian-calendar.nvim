# Obsidian Calendar

A Neovim plugin for viewing a calendar of your daily notes in Obsidian-style markdown vaults.

## Todo

- [ ] display the calendar
- [ ] add sign for notes
- [ ] add sign diagnostics

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  dir = '/Users/ondrejhlavacka/Personal/0_Code/lua/obsidian-calendar',
  config = function()
    require('obsidian-calendar').setup({
      -- Configuration options will be added here
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

## Configuration

Currently, the plugin is in its initial skeleton phase. Configuration options will be added as features are developed.

```lua
require('obsidian-calendar').setup({
  -- Configuration options coming soon
})
```

## Development Status

This plugin is currently a basic skeleton. The calendar view shows a placeholder message to confirm the plugin loads correctly.

## License

TBD
