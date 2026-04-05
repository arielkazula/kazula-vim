-- lua/core/fzf_quick_sheet.lua -------------------------------------------
-- A custom "Quick Sheet" for fzf-lua to remember and trigger 
-- specific search patterns and directory-scoped searches.

local M = {}

function M.show_quick_sheet()
    local fzf = require('fzf-lua')
    
    -- Define your favorite search patterns here
    -- Format: ["Display Label"] = { command_to_run }
    local sheet_items = {
        ["[Project] Search: TODO / FIXME"]    = function() fzf.live_grep({ search = "TODO|FIXME" }) end,
        ["[Project] Search: Error Logs"]      = function() fzf.live_grep({ search = "ERROR|CRITICAL|FAIL" }) end,
        ["[C++] Search: Include Headers"]     = function() fzf.live_grep({ search = "#include" }) end,
        ["[C++] Files: Source and Headers"]   = function() fzf.files({ cmd = "rg --files -g '*.{c,cpp,h,hpp,cc}'" }) end,
        ["[Config] Files: Neovim Config"]     = function() fzf.files({ cwd = vim.fn.stdpath("config") }) end,
        ["[Config] Search: Keymaps"]          = function() fzf.keymaps() end,
        ["[System] Files: Recent Files"]      = function() fzf.oldfiles() end,
        ["[Help] Quick Help: Built-in Pickers"] = function() fzf.builtin() end,
    }

    local options = vim.tbl_keys(sheet_items)
    table.sort(options)

    fzf.fzf_exec(options, {
        prompt = "Search Quick Sheet❯ ",
        actions = {
            ["default"] = function(selected)
                local choice = sheet_items[selected[1]]
                if choice then choice() end
            end
        },
        winopts = {
            title = " Search Quick Sheet ",
            height = 0.4,
            width = 0.6,
            row = 0.5,
            col = 0.5,
            border = "rounded",
        }
    })
end

return M
