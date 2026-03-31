-- lua/plugins/tools.lua --------------------------------------------------
-- This file contains productivity tools for task management, 
-- formatting, searching & replacing, and sessions.

return {
    -- Sophisticated task runner (Overseer)
    -- Automates Python execution, C++ builds, and Docker tasks.
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
    -- Replaces heavy tools like null-ls with native Lua-based formatting.
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
    -- Replaces Spectre with a better UI that uses an editable buffer.
    {
        "magicduck/grug-far.nvim",
        cmd = "GrugFar",
        opts = {
            headerMaxWidth = 80,
            transient = true, -- Close automatically after use
        },
    },

    -- Simple and reliable session management (Persistence.nvim)
    -- Automatically saves and restores your workspace state.
    {
        "folke/persistence.nvim",
        event = "BufReadPre", -- only load if we open a file
        opts = { options = { "buffers", "curdir", "tabpages", "winsize" } },
    },

    -- Regex-powered search/replace within current buffer
    {
        "chrisgrieser/nvim-rip-substitute",
        cmd = "RipSubstitute",
        opts = { highlight = { duration = 500 } },
    },

    -- Utilities
    {
        "echasnovski/mini.nvim",
        version = "*",
        event = "VeryLazy",
        config = function()
            -- Surround: Add/Delete/Replace brackets/quotes (gs mappings)
            require("mini.surround").setup({
                mappings = {
                    add = "gsa", delete = "gsd", find = "gsf",
                    find_left = "gsF", highlight = "gsh",
                    replace = "gsr", update_n_lines = "gsn",
                },
            })
            -- Move: Move lines/selections with Meta+hjkl
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
