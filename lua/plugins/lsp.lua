-- lua/plugins/lsp.lua ----------------------------------------------------
-- This file manages the Language Server Protocol (LSP) and Treesitter 
-- (syntax highlighting) integration using the modern v2.0+ APIs.

return {
    -- 1. Mason: The external tool manager
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = { ui = { border = "rounded" } },
        config = function(_, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            -- tools to ensure are installed
            local packages = { "clang-format", "jq", "black", "codespell", "shfmt", "stylua" }
            for _, tool in ipairs(packages) do
                local p = mr.get_package(tool)
                if not p:is_installed() then p:install() end
            end
        end,
    },

    -- 2. Mason-LSPConfig: Bridges Mason with Neovim's LSP
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
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- Fix Position Encodings Warning
            capabilities.offsetEncoding = { "utf-16" }

            -- Specialized configuration for Clangd (C++)
            local clangd_config = {
                capabilities = capabilities,
                cmd = {
                    "clangd",
                    "-j=4",
                    "--background-index",
                    "--clang-tidy",
                    "--completion-style=detailed",
                    "--header-insertion=never",
                    "--fallback-style=llvm",
                    "--offset-encoding=utf-16",
                    "--function-arg-placeholders=true", -- FIX: requires boolean value
                },
            }

            -- Specialized configuration for Lua
            local lua_config = {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                    },
                },
            }

            -- Apply configurations
            if vim.lsp.config then
                vim.lsp.config("*", { capabilities = capabilities })
                vim.lsp.config("clangd", clangd_config)
                vim.lsp.config("lua_ls", lua_config)
            else
                local lspconfig = require("lspconfig")
                lspconfig.clangd.setup(clangd_config)
                lspconfig.lua_ls.setup(lua_config)
                lspconfig.util.default_config = vim.tbl_extend("force", lspconfig.util.default_config, {
                    capabilities = capabilities,
                })
            end

            require("mason-lspconfig").setup(opts)
        end,
    },

    -- 3. Core LSP Plugin
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp", "p00f/clangd_extensions.nvim" },
        config = function()
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
        end,
    },

    -- Treesitter
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

    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPost",
        opts = { mode = "cursor", max_lines = 3 },
    },

    -- Documentation (Neogen)
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

    -- Diagnostics UI (Trouble)
    {
        "folke/trouble.nvim",
        cmd = { "Trouble" },
        opts = { modes = { lsp = { win = { position = "right" } } } },
    },

    -- Todo-comments
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
