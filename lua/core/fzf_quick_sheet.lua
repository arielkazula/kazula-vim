-- lua/core/fzf_quick_sheet.lua -------------------------------------------
-- A custom "Quick Sheet" for fzf-lua to remember and trigger 
-- specific search patterns and directory-scoped searches.

local M = {}

function M.show_quick_sheet()
    local fzf = require('fzf-lua')
    
    -- Define your favorite search patterns here
    local sheet_items = {
        ["[Project] Search: TODO / FIXME"]    = function() fzf.live_grep({ search = "TODO|FIXME" }) end,
        ["[Project] Search: Error Logs"]      = function() fzf.live_grep({ search = "ERROR|CRITICAL|FAIL" }) end,
        ["[C++] Search: Include Headers"]     = function() fzf.live_grep({ search = "#include" }) end,
        ["[C++] Search: Literal (No Regex)"]  = function() fzf.live_grep({ rg_opts = "--column --line-number --no-heading --color=always --smart-case --fixed-strings -e" }) end,
        ["[C++] Files: Source and Headers"]   = function() fzf.files({ cmd = "rg --files -g '*.{c,cpp,h,hpp,cc}'" }) end,
        ["[Scoped] Search: Only in 'src/'"]   = function() fzf.live_grep({ cwd = "./src" }) end,
        ["[Scoped] Search: Exclude 'tests/'"]  = function() fzf.live_grep({ rg_opts = "--column --line-number --no-heading --color=always --smart-case -g '!tests/*' -e" }) end,
        ["[Type] Search: Only Lua Files"]     = function() fzf.live_grep({ rg_opts = "--column --line-number --no-heading --color=always --smart-case -tlua -e" }) end,
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
