-- lua/plugins/ui.lua -----------------------------------------------------
-- This file handles the visual aspects of Neovim, including themes, 
-- statuslines, Git indicators, and dashboard.

return {
    -- Modern and fast dark theme (OneDark)
    -- Optimized with specific highlights for better TreeSitter and LSP feedback.
    {
        "navarasu/onedark.nvim",
        priority = 1000, -- Load this before anything else
        config = function()
            require("onedark").setup({
                style = "dark",
                transparent = true,
                term_colors = true,
                ending_tildes = false,
                code_style = {
                    comments = "italic",
                    keywords = "none",
                    functions = "none",
                    strings = "none",
                    variables = "none",
                },
                highlights = {
                    ["@comment.documentation"] = { fg = "#3cb371" },
                },
                diagnostics = {
                    darker = true,
                    undercurl = true,
                    background = false,
                },
            })
            require("onedark").load()
        end,
    },

    -- Minimalist and fast statusline (Lualine.nvim)
    -- Replaced default section separators to maintain a "flat" and modern look.
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme = "onedark",
                section_separators = "",
                component_separators = "",
                globalstatus = true, -- Shared statusline across all windows
            },
        },
    },

    -- High-performance Git indicators (Gitsigns.nvim)
    -- Shows line additions, changes, and deletions in the gutter (sign column).
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add = { text = "│" },
                change = { text = "│" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
        },
    },

    -- Comprehensive QoL modules (Snacks.nvim)
    -- Replaces several smaller plugins with a single, highly optimized suite.
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            bigfile   = { enabled = true }, -- Optimizes performance for large files
            dashboard = {
                preset = {
                    header = [[
██╗  ██╗ █████╗ ███████╗██╗   ██╗██╗      █████╗     ██╗   ██╗██╗███╗   ███╗
██║ ██╔╝██╔══██╗╚══███╔╝██║   ██║██║     ██╔══██╗    ██║   ██║██║████╗ ████║
█████╔╝ ███████║  ███╔╝ ██║   ██║██║     ███████║    ██║   ██║██║██╔████╔██║
██╔═██╗ ██╔══██║ ███╔╝  ██║   ██║██║     ██╔══██║    ╚██╗ ██╔╝██║██║╚██╔╝██║
██║  ██╗██║  ██║███████╗╚██████╔╝███████╗██║  ██║     ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
                    keys = {
                        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                        { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                },
            },
            indent    = { enabled = true }, -- Shows indentation guides (replacing indent-blankline)
            input     = { enabled = true }, -- Nicer prompt for vim.ui.input
            notifier  = { enabled = true }, -- Elegant notification system
            quickfile = { enabled = true }, -- Loads file content instantly before plugins finish
            words     = { enabled = true }, -- Highlights other occurrences of the word under cursor
        },
    },

    -- Discovery tool for keybindings (Which-Key.nvim)
    -- Provides an interactive popup menu that helps you remember your shortcuts.
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
            },
        },
    },

    -- Better icons for various plugins
    { "nvim-tree/nvim-web-devicons", lazy = true },
}
