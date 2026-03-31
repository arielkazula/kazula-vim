-- lua/plugins/ui.lua -----------------------------------------------------
-- This file handles the visual aspects of Neovim, including themes, 
-- statuslines, advanced UI components, and modern folding.

return {
    -- Modern and fast dark theme (OneDark)
    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require("onedark").setup({
                style = "dark",
                transparent = true,
                term_colors = true,
                highlights = {
                    ["@comment.documentation"] = { fg = "#3cb371" },
                },
            })
            require("onedark").load()
        end,
    },

    -- Minimalist and fast statusline (Lualine.nvim)
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme = "onedark",
                section_separators = "",
                component_separators = "",
                globalstatus = true,
            },
        },
    },

    -- Experimental: Modernize the Command Line, Messages, and Popupmenu
    -- Replaces the bottom command line with a floating prompt.
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = true,
            },
        },
    },

    -- High-performance folding (nvim-ufo)
    -- Makes folding as pretty and fast as VS Code.
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        init = function()
            -- Fold settings needed for ufo
            vim.o.foldcolumn = '1'
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        opts = {
            provider_selector = function(bufnr, filetype, buftype)
                return {'treesitter', 'indent'}
            end
        },
    },

    -- Gitsigns
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
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            bigfile   = { enabled = true },
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
            indent    = { enabled = true },
            input     = { enabled = true },
            notifier  = { enabled = true },
            quickfile = { enabled = true },
            words     = { enabled = true },
        },
    },

    -- Discovery tool
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
        },
    },

    { "nvim-tree/nvim-web-devicons", lazy = true },
}
