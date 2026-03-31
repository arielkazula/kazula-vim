-- lua/plugins/lsp.lua ----------------------------------------------------
-- This file manages LSP and Treesitter using Neovim 0.11+ native APIs.
-- It avoids the deprecated nvim-lspconfig "framework" (setup calls).

return {
    -- 1. Mason: Tool management
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = { ui = { border = "rounded" } },
        config = function(_, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            local packages = { "clang-format", "jq", "black", "codespell", "shfmt", "stylua" }
            for _, tool in ipairs(packages) do
                local p = mr.get_package(tool)
                if not p:is_installed() then p:install() end
            end
        end,
    },

    -- 2. Mason-LSPConfig: Bridges Mason with native LSP
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            ensure_installed = {
                "clangd", "bashls", "pyright", "cmake",
                "lua_ls", "harper_ls", "marksman", "jsonls",
            },
            automatic_enable = true,
        },
        config = function(_, opts)
            -- Ensure nvim-lspconfig is loaded so it registers templates with vim.lsp.config
            require("lspconfig")
            
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            capabilities.offsetEncoding = { "utf-16" }

            -- Set global defaults for ALL servers using the new 0.11 API
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            -- Specialized configuration for Clangd (C++)
            -- Restored performance flags and added priority settings.
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "-j=4",
                    "--background-index",
                    "--background-index-priority=background",
                    "--clang-tidy",
                    "--completion-style=detailed",
                    "--enable-config",
                    "--fallback-style=llvm",
                    "--header-insertion=never",
                    "--malloc-trim",
                    "--pch-storage=disk",
                    "--offset-encoding=utf-16",
                    "--function-arg-placeholders=true",
                },
            })

            -- Specialized configuration for Lua
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                    },
                },
            })

            -- Optimized Harper (Grammar/Spell Check)
            vim.lsp.config("harper_ls", {
                settings = {
                    ["harper-ls"] = { linters = { spell_check = true } },
                },
            })

            -- Finally, initialize mason-lspconfig to enable the servers
            require("mason-lspconfig").setup(opts)
        end,
    },

    -- 3. Core LSP Plugin: Global UI and Handlers
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp", "p00f/clangd_extensions.nvim" },
        config = function()
            -- Set up global UI preferences
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
            
            -- Initialize clangd_extensions (non-LSP features like hints)
            require("clangd_extensions").setup({
                extensions = { autoSetHints = true, inlay_hints = { inline = false } },
            })
        end,
    },

    -- Advanced Syntax Highlighting (Treesitter)
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        opts = {
            ensure_installed = {
                "bash", "json", "lua", "markdown", "markdown_inline",
                "python", "regex", "vim", "cpp", "c", "vimdoc",
            },
            highlight = { enable = true },
            indent = { enable = true },
        },
        config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
    },

    -- Sticky context header
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPost",
        opts = { mode = "cursor", max_lines = 3 },
    },

    -- Documentation Generator (Neogen)
    {
        "danymat/neogen",
        cmd = "Neogen",
        opts = {
            enabled = true,
            languages = {
                cpp = {
                    template = {
                        annotation_convention = "custom",
                        custom = {
                            { nil, "/**", { no_results = true, type = { "func", "file" } } },
                            { nil, " * @file", { no_results = true, type = { "file" } } },
                            { nil, " * $1", { no_results = true, type = { "func", "file" } } },
                            { nil, " */", { no_results = true, type = { "func", "file" } } },
                            { nil, "" },
                            { nil, "/**", { type = { "func" } } },
                            { nil, " * $1", { type = { "func" } } },
                            { nil, " *" },
                            { "tparam", " * @tparam %s $1" },
                            { "parameters", " * @param %s $1" },
                            { "return_statement", " * @return $1" },
                            { nil, " */" },
                        },
                    },
                },
            },
        },
    },

    -- Improved Diagnostic UI (Trouble)
    {
        "folke/trouble.nvim",
        cmd = { "Trouble" },
        opts = { modes = { lsp = { win = { position = "right" } } } },
    },

    -- Todo comments
    {
        "folke/todo-comments.nvim",
        event = "BufReadPost",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            colors = {
                error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
                info = { "DiagnosticInfo", "#2563EB" },
                hint = { "DiagnosticHint", "#10B981" },
                test = { "Identifier", "#FF00FF" },
            },
        },
    },
}
