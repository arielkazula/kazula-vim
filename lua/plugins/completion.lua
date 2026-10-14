-- lua/plugins/completion.lua ---------------------------------------------
-- This file handles the autocompletion engine and snippet support.
-- Using blink.cmp, a high-performance completion engine written in Rust.

return {
    {
        "saghen/blink.cmp",
        version = '*', -- Use pre-built binaries (stable, no cargo build needed)
        dependencies = {
            "rafamadriz/friendly-snippets",
            "saghen/blink.lib",
            -- Add lazydev for better Neovim Lua API completion
            {
                "folke/lazydev.nvim",
                ft = "lua", -- only load on lua files
                opts = {
                    library = {
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                    },
                },
            },
            -- GitHub issues / PRs / mentions in commit messages and Octo
            "Kaiser-Yang/blink-cmp-git",
        },
        opts = {
            -- super-tab: <Tab> accepts / jumps snippet fields, <S-Tab> back,
            -- <C-n>/<C-p> navigate. Copilot accepts with <M-l> (keymaps.lua).
            keymap = { preset = "super-tab" },
            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = "mono",
            },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 500 },
                -- Disabled so it doesn't clash with Copilot's inline ghost text
                ghost_text = { enabled = false },
            },
            sources = {
                -- Added 'lazydev' to the default list of providers
                default = { "lsp", "path", "snippets", "buffer", "lazydev", "git" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100, -- show at the top
                    },
                    git = {
                        name = "Git",
                        module = "blink-cmp-git",
                        enabled = function()
                            return vim.tbl_contains(
                                { "gitcommit", "octo", "NeogitCommitMessage" },
                                vim.bo.filetype
                            )
                        end,
                    },
                },
            },
            signature = { enabled = true },
        },
        opts_extend = { "sources.default" },
    },

    -- Collection of common snippets for all languages
    { "rafamadriz/friendly-snippets", lazy = true },
}
