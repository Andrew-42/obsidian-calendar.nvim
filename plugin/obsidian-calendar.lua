if vim.g.loaded_obsidian_calendar then
    return
end

vim.g.loaded_obsidian_calendar = 1

vim.api.nvim_create_user_command("ObsidianCalendar", function()
    require("obsidian-calendar").open()
end, {
    desc = "Open the Obsidian calendar view",
})
