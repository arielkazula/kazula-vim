-- plugins/ui.lua ---------------------------------------------------------
return {
    -- Theme
    {
        "navarasu/onedark.nvim",
        config = function()
            require("onedark").setup({
                -- Main options --
                style = "dark",               -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
                transparent = true,           -- Show/hide background
                term_colors = true,           -- Change terminal color as per the selected theme style
                ending_tildes = false,        -- Show the end-of-buffer tildes. By default they are hidden
                cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu

                -- toggle theme style ---
                toggle_style_key = nil,                                                              -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
                toggle_style_list = { "dark", "darker", "cool", "deep", "warm", "warmer", "light" }, -- List of styles to toggle between

                -- Change code style ---
                -- Options are italic, bold, underline, none
                -- You can configure multiple style with comma separated, For e.g., keywords = 'italic,bold'
                code_style = {
                    comments = "italic",
                    keywords = "none",
                    functions = "none",
                    strings = "none",
                    variables = "none",
                },

                -- Lualine options --
                lualine = {
                    transparent = false, -- lualine center bar transparency
                },

                -- Custom Highlights --
                colors = {}, -- Override default colors
                highlights = {
                    -- Tree-sitter specific highlight groups
                    --["@comment"] = { fg = "#228B22" }, -- Dark green for Tree-sitter comments
                    ["@comment.documentation"] = { fg = "#3cb371" }, -- Dark green for Tree-sitter documentation comments
                },                                                   -- Override highlight groups

                -- Plugins Config --
                diagnostics = {
                    darker = true,      -- darker colors for diagnostic
                    undercurl = true,   -- use undercurl instead of underline for diagnostics
                    background = false, -- use background color for virtual text
                },
            })
            -- Enable theme
            require('onedark').load()
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        opts = { options = { theme = "gruvbox", section_separators = "", component_separators = "" } }
    },

    -- Git decorations
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = { add = { text = "│" }, change = { text = "│" }, delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" } },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
            end,
        },
    },

    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts_extend = { "spec" },
        opts = {
            preset = "helix",
            defaults = {},
            spec = {
                {
                    mode = { "n", "v" },
                    { "<leader><tab>", group = "tabs" },
                    { "<leader>c", group = "code" },
                    { "<leader>d", group = "debug" },
                    { "<leader>dp", group = "profiler" },
                    { "<leader>f", group = "file/find" },
                    { "<leader>g", group = "git" },
                    { "<leader>gh", group = "hunks" },
                    { "<leader>q", group = "quit/session" },
                    { "<leader>s", group = "search" },
                    { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
                    { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
                    { "[", group = "prev" },
                    { "]", group = "next" },
                    { "g", group = "goto" },
                    { "gs", group = "surround" },
                    { "z", group = "fold" },
                    {
                        "<leader>b",
                        group = "buffer",
                        expand = function()
                            return require("which-key.extras").expand.buf()
                        end,
                    },
                    {
                        "<leader>w",
                        group = "windows",
                        proxy = "<c-w>",
                        expand = function()
                            return require("which-key.extras").expand.win()
                        end,
                    },
                    -- better descriptions
                    { "gx", desc = "Open with system app" },
                },
            },
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Keymaps (which-key)",
            },
            {
                "<c-w><space>",
                function()
                    require("which-key").show({ keys = "<c-w>", loop = true })
                end,
                desc = "Window Hydra Mode (which-key)",
            },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
            if not vim.tbl_isempty(opts.defaults) then
                LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
                wk.register(opts.defaults)
            end
        end,
    }
    ,

    -- Comments
    { "numToStr/Comment.nvim", opts = {} },

    -- Auto-pairs
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

    -- Indent guides
    { "lukas-reineke/indent-blankline.nvim"
    },
    {
        "folke/snacks.nvim",
        opts = {
            scroll = { enabled = false },
            explorer = { enabled = false },
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
                    -- stylua: ignore
                    ---@type snacks.dashboard.Item[]
                    keys = {
                        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                        { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
                        { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                },
            },
        },
    },
    {
        "desdic/greyjoy.nvim",
        dependencies = {
            { "akinsho/toggleterm.nvim" }, -- Optional
        },
        cmd = { "Greyjoy", "Greyedit", "GreyjoyTelescope", "GreyjoyFzf", "GreyjoyRunLast" },
        config = function()
            local greyjoy = require("greyjoy")
            local condition = require("greyjoy.conditions")
            greyjoy.setup({
                output_results = require("greyjoy.terminals").term,
                -- output_results = require("greyjoy.terminals").toggleterm,
                extensions = {
                    generic = {
                        commands = {
                            ["run {filename}"] = { command = { "python3", "{filename}" }, filetype = "python" },
                            ["generate compile_commands"] = { command = { "./src/scripts/gen_compile_commands.sh" } },
                        },
                    },
                    docker_compose = { group_id = 2 },
                },
                run_groups = { fast = { "generic", "docker_compose" } },
            })

            greyjoy.load_extension("generic") -- optional
        end,
    },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            sign_priority = 8,
            keywords = {
                FIX = {
                    icon = " ",
                    color = "error",
                    alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
                },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
            },
            gui_style = {
                fg = "NONE",
                bg = "BOLD",
            },
            merge_keywords = true,
            highlight = {
                multiline = true,
                multiline_pattern = "^.",
                multiline_context = 10,
                before = "",
                keyword = "wide",
                after = "fg",
                pattern = [[.*<(KEYWORDS)\s*:]],
                comments_only = true,
                max_line_len = 400,
                exclude = {},
            },
            colors = {
                error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
                info = { "DiagnosticInfo", "#2563EB" },
                hint = { "DiagnosticHint", "#10B981" },
                default = { "Identifier", "#7C3AED" },
                test = { "Identifier", "#FF00FF" },
            },
            search = {
                command = "rg",
                args = {
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                },
                pattern = [[\b(KEYWORDS):]],
            },
        },
    },

    -- Allow moving lines up down left right
    {
        "echasnovski/mini.nvim",
        version = "*",
        config = function()
            require("mini.move").setup({
                -- Module mappings. Use `''` (empty string) to disable one.
                mappings = {
                    -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
                    left = "",
                    right = "",
                    down = "<M-j>",
                    up = "<M-k>",

                    -- Move current line in Normal mode
                    line_left = "",
                    line_right = "",
                    line_down = "<M-j>",
                    line_up = "<M-k>",
                },
            })
        end,
    },
    -- nvim-rip-substitute plugin configuration
    {
        "chrisgrieser/nvim-rip-substitute",
        cmd = "RipSubstitute",
        config = function()
            require("rip-substitute").setup({
                highlight = {
                    duration = 500, -- Highlight duration in milliseconds
                },
            })
        end,
    },
    {
        "briangwaltney/paren-hint.nvim",
        lazy = false,
        config = function()
            -- you can create a custom highlight group for the ghost text with the below command.
            -- change the `highlight` option to `parenhint` if you use this method.
            -- vim.api.nvim_exec([[ highlight parenhint guifg='#56633E' ]], false)
            require("paren-hint").setup({
                -- Include the opening paren in the ghost text
                include_paren = false,

                -- Show ghost text when cursor is anywhere on the line that includes the close paren rather just when the cursor is on the close paren
                anywhere_on_line = true,

                -- show the ghost text when the opening paren is on the same line as the close paren
                show_same_line_opening = false,

                -- style of the ghost text using highlight group
                -- :Telescope highlights to see the available highlight groups if you have telescope installed
                highlight = "Comment",

                -- excluded filetypes
                excluded_filetypes = {
                    "lspinfo",
                    "packer",
                    "checkhealth",
                    "help",
                    "man",
                    "gitcommit",
                    "TelescopePrompt",
                    "TelescopeResults",
                    "",
                },
                -- excluded buftypes
                excluded_buftypes = {
                    "terminal",
                    "nofile",
                    "quickfix",
                    "prompt",
                },
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-context"
    },
}

