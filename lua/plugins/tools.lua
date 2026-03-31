-- lua/plugins/tools.lua --------------------------------------------------
-- This file contains productivity tools for task management, 
-- formatting, searching & replacing, and sessions.

return {
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

    -- Lightweight and fast formatter (Conform.nvim)
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
                cpp = { "clang-format" },
                c = { "clang-format" },
                sh = { "shfmt" },
            },
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
        },
    },

    -- Powerful project-wide find and replace (Grug-Far)
    {
        "magicduck/grug-far.nvim",
        cmd = "GrugFar",
        opts = { headerMaxWidth = 80, transient = true },
    },

    -- Simple and reliable session management (Persistence.nvim)
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = { options = { "buffers", "curdir", "tabpages", "winsize" } },
    },

    -- Regex-powered search/replace within current buffer
    {
        "chrisgrieser/nvim-rip-substitute",
        cmd = "RipSubstitute",
        opts = { highlight = { duration = 500 } },
    },

    -- Lag-free mode switching (better-escape.nvim)
    -- Allows using 'jk' or 'jj' to exit insert mode instantly.
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

    -- Enhanced increment/decrement (dial.nvim)
    -- Toggles true/false, increments dates, hex colors, and more with <C-a>/<C-x>.
    {
        "monaqa/dial.nvim",
        keys = {
            { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
            { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
        },
        config = function()
            local augend = require("dial.augend")
            require("dial.config").augends:register_group({
                default = {
                    augend.integer.alias.decimal,
                    augend.integer.alias.hex,
                    augend.date.alias["%Y/%m/%d"],
                    augend.constant.alias.bool,
                    augend.semver.alias.semver,
                },
            })
        end,
    },

    -- Utilities (mini.nvim)
    {
        "echasnovski/mini.nvim",
        version = "*",
        event = "VeryLazy",
        config = function()
            require("mini.surround").setup({
                mappings = {
                    add = "gsa", delete = "gsd", find = "gsf",
                    find_left = "gsF", highlight = "gsh",
                    replace = "gsr", update_n_lines = "gsn",
                },
            })
            require("mini.move").setup({
                mappings = {
                    left = "", right = "",
                    down = "<M-j>", up = "<M-k>",
                    line_left = "", line_right = "",
                    line_down = "<M-j>", line_up = "<M-k>",
                },
            })
        end,
    },
}
