-- obsidian-calendar.lua
-- Main plugin entry point - auto-loaded by Neovim

if vim.g.loaded_obsidian_calendar then
    return
end
vim.g.loaded_obsidian_calendar = 1

-- Create the main user command
vim.api.nvim_create_user_command("ObsidianCalendar", function()
    require("obsidian-calendar").open()
end, {
    desc = "Open the Obsidian calendar view",
})
