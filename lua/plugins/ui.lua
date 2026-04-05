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

    -- Modernized Command Line and Notifications (Noice)
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
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        init = function()
            vim.o.foldcolumn = '0' 
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

    -- Git Conflict Resolution UI
    -- Provides high-visibility markers and one-key resolution for merge conflicts.
    {
        "akinsho/git-conflict.nvim",
        version = "*",
        config = true,
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

    -- Visual Tab Bar (Bufferline)
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                mode = "buffers",
                separator_style = "thin",
                show_buffer_close_icons = false,
                show_close_icon = false,
                diagnostics = "nvim_lsp",
                offsets = {
                    {
                        filetype = "oil",
                        text = "File Explorer",
                        text_align = "left",
                        separator = true,
                    },
                },
            },
        },
    },

    -- Code Outline (Aerial)
    {
        "stevearc/aerial.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
        opts = {
            on_attach = function(bufnr)
                -- Jump forwards/backwards with '{' and '}'
                vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
            end,
            layout = {
                max_width = { 40, 0.2 },
                min_width = 20,
            },
            show_guides = true,
        },
    },

    -- Better UI Primitives (Dressing)
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        opts = {
            input = { border = "rounded" },
            select = { backend = { "fzf_lua", "builtin" } },
        },
    },

    { "nvim-tree/nvim-web-devicons", lazy = true },
}
