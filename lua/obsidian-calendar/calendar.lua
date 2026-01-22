-- calendar.lua
-- Calendar rendering and display logic

local M = {}

-- Show the calendar view in a new buffer
function M.show()
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'obsidian-calendar', { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  -- Create placeholder content
  local content = {
    '╔═══════════════════════════════════════╗',
    '║                                       ║',
    '║     OBSIDIAN CALENDAR VIEW            ║',
    '║                                       ║',
    '║     Calendar Coming Soon...           ║',
    '║                                       ║',
    '║     Plugin successfully loaded!       ║',
    '║                                       ║',
    '╚═══════════════════════════════════════╝',
    '',
    'Press q to close this buffer',
  }

  -- Set the content
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  -- Open the buffer in a new window
  vim.api.nvim_command('split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Set buffer-local keymaps
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', {
    noremap = true,
    silent = true,
    desc = 'Close calendar view'
  })
end

return M
