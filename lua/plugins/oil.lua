-- plugins/oil.lua --------------------------------------------------------
return {
    {
        "stevearc/oil.nvim",
        dependencies = {
            -- optional icon support; keep as you prefer
            "echasnovski/mini.icons",
        },

        lazy = false,
        config = function()
            require("oil").setup({
                -- 1. Hijack `:edit` and `nvim .` on directories
                default_file_explorer = true,

                -- 2. Show dotfiles
                view_options = {
                    show_hidden = true,
                },

                -- 3. Don’t prompt on simple edits (e.g. creating a new file)
                skip_confirm_for_simple_edits = true,

                -- 4. Git actions: only auto-mv
                git = {
                    add = function() return false end,
                    mv  = function() return true end,
                    rm  = function() return false end,
                },

                -- 5. Floating window layout
                float = {
                    padding     = 2,
                    max_height  = 30, -- rows
                    max_width   = 120,
                    border      = "rounded",
                    win_options = {
                        winblend = 10,
                    },
                },

                -- Configuration for the file preview window
                preview_win = {
                    -- Whether the preview window is automatically updated when the cursor is moved
                    update_on_cursor_moved = true,
                    -- How to open the preview window "load"|"scratch"|"fast_scratch"
                    preview_method = "fast_scratch",
                    -- A function that returns true to disable preview on a file e.g. to avoid lag
                    disable_preview = function(filename)
                        return false
                    end,
                    -- Window-local options to use for preview window buffers
                    win_options = {},
                },

                -- 6. In-window keymaps
                keymaps = {
                    ["q"]         = "actions.close", -- q to close
                    ["<leader>e"] = "actions.close", -- Ctrl+e also closes
                },
            })
        end,
    },
}
