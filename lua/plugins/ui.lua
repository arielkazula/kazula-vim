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
        -- Notifications are rendered by snacks.notifier (no nvim-notify).
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
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
                return { 'treesitter', 'indent' }
            end
        },
    },

    -- Git plugins (gitsigns, git-conflict, …) live in plugins/git.lua.

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
                -- Jump between symbols with [s / ]s (keeps native { } paragraph motions)
                vim.keymap.set("n", "[s", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Prev symbol" })
                vim.keymap.set("n", "]s", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol" })
            end,
            layout = {
                max_width = { 40, 0.2 },
                min_width = 20,
            },
            show_guides = true,
        },
    },

    -- vim.ui.select → fzf-lua (navigation.lua); vim.ui.input → snacks.input.

    { "nvim-tree/nvim-web-devicons", lazy = true },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        -- Dependencies are required for parsing the markdown and showing icons
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons" -- Use 'echasnovski/mini.icons' if you prefer
        },
        ft = { "markdown" },
        opts = {
            -- The plugin comes with great defaults, but we can tweak it
            code = {
                -- Highlights code blocks with a slightly different background
                sign = true,
                width = 'block',
                right_pad = 1,
            },
        },
    },
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        dependencies = { "folke/twilight.nvim" },
        opts = {
            window = {
                -- This dictates the width of the centered text.
                -- 100 to 120 columns usually feels very close to GitHub's max-width.
                width = 120,
                options = {
                    -- These options apply ONLY when Zen Mode is active
                    signcolumn = "no", -- Hides the gutter on the left
                    number = false,    -- Hides line numbers for a cleaner look
                    relativenumber = false,
                    foldcolumn = "0",  -- Hides fold markers
                    list = false,      -- Hides whitespace characters
                },
            },
            plugins = {
                -- Dims the background outside the centered window
                twilight = { enabled = true },
            }
        }
    },

    -- Dims inactive code (used by zen-mode)
    { "folke/twilight.nvim", cmd = { "Twilight", "TwilightEnable", "TwilightDisable" }, opts = {} },
}
