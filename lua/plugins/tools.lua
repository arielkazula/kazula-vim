-- lua/plugins/tools.lua --------------------------------------------------
-- Productivity tools: formatting, task running, search/replace, sessions,
-- Git visualization, and editor utilities.

return {
    -- ── Formatting (conform.nvim) ────────────────────────────────────────
    -- Single source of truth for all formatters. Falls back to LSP for
    -- filetypes not listed here. Formatters are installed via Mason.
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd   = { "ConformInfo" },
        opts  = {
            formatters_by_ft = {
                -- C / C++ — clang-format (Mason: clang-format)
                c        = { "clang_format" },
                cpp      = { "clang_format" },
                cc       = { "clang_format" },
                h        = { "clang_format" },
                hpp      = { "clang_format" },
                -- Data
                json     = { "jq" },
                -- Python — black (Mason: black)
                python   = { "black" },
                -- Shell — shfmt (Mason: shfmt)
                sh       = { "shfmt" },
                bash     = { "shfmt" },
                -- Lua — stylua (Mason: stylua)
                lua      = { "stylua" },
                -- Markdown / prose — prettier (Mason: prettier)
                markdown = { "prettier" },
            },
            -- Auto-format on save; fall back to the attached LSP for any
            -- filetype not explicitly listed above.
            format_on_save = {
                timeout_ms   = 2000,
                lsp_format = "fallback",
            },
        },
    },

    -- Session management (<leader>q*)
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {},
    },

    -- CMake integration (<leader>cm*)
    {
        "Civitasv/cmake-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = {
            "CMakeGenerate", "CMakeBuild", "CMakeRun", "CMakeStop",
            "CMakeSelectBuildTarget", "CMakeSelectBuildType",
        },
        opts = {},
    },

    -- Refactoring operations (<leader>cx*)
    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
        cmd = "Refactor",
        opts = {},
    },

    -- Sophisticated task runner (Overseer)
    {
        "stevearc/overseer.nvim",
        cmd = { "OverseerRun", "OverseerToggle", "OverseerInfo", "OverseerBuild" },
        opts = {
            templates = { "builtin", "user.custom_tasks" },
            task_list = { direction = "right" },
        },
        config = function(_, opts)
            require("overseer").setup(opts)
        end,
    },

    -- Powerful project-wide find and replace (Grug-Far)
    {
        "magicduck/grug-far.nvim",
        cmd = "GrugFar",
        opts = { headerMaxWidth = 80, transient = true },
    },

    -- Git plugins (neogit, diffview, …) live in plugins/git.lua.

    -- Regex-powered search/replace within current buffer
    {
        "chrisgrieser/nvim-rip-substitute",
        cmd = "RipSubstitute",
        opts = { highlight = { duration = 500 } },
    },

    -- Lag-free mode switching (better-escape.nvim)
    {
        "max397574/better-escape.nvim",
        event = "InsertEnter",
        opts = {
            timeout = 200,
            default_mappings = true,
            mappings = {
                i = { j = { k = "<Esc>", j = "<Esc>" } },
                c = { j = { k = "<Esc>", j = "<Esc>" } },
                t = { j = { k = "<C-\\><C-n>", j = "<C-\\><C-n>" } },
                v = { j = { k = "<Esc>", j = "<Esc>" } },
                s = { j = { k = "<Esc>", j = "<Esc>" } },
            },
        },
    },


    -- Utilities (mini.nvim)
    {
        "echasnovski/mini.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = {
            -- textobjects queries (function/class/parameter) for mini.ai
            { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
        },
        config = function()
            -- 0. Text objects: af/if function, ac/ic class, aa/ia argument (+ mini.ai builtins)
            local ai = require("mini.ai")
            ai.setup({
                n_lines = 500,
                custom_textobjects = {
                    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
                    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
                    a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
                },
            })
            -- 1. Auto-pairing (Brackets, quotes, etc.)
            require("mini.pairs").setup({})

            -- 2. Surrounding (Add/delete/replace surroundings)
            require("mini.surround").setup({
                mappings = {
                    add = "gsa",
                    delete = "gsd",
                    find = "gsf",
                    find_left = "gsF",
                    highlight = "gsh",
                    replace = "gsr",
                    update_n_lines = "gsn",
                },
            })

            -- 3. Movement (Move lines and selections)
            require("mini.move").setup({
                mappings = {
                    left = "",
                    right = "",
                    down = "<M-j>",
                    up = "<M-k>",
                    line_left = "",
                    line_right = "",
                    line_down = "<M-j>",
                    line_up = "<M-k>",
                },
            })
        end,
    },
}
