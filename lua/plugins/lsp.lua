-- lua/plugins/lsp.lua ----------------------------------------------------
-- This file manages the Language Server Protocol (LSP) and Treesitter 
-- (syntax highlighting) integration.

return {
    -- Automatic installation of LSPs and tools
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

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            ensure_installed = {
                "clangd", "bashls", "pyright", "cmake",
                "lua_ls", "harper_ls", "marksman", "jsonls",
            },
            automatic_installation = true,
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local mlsp = require("mason-lspconfig")
            local blink = require("blink.cmp")
            
            -- Initialize mason-lspconfig with the options
            mlsp.setup(opts)

            -- Get capabilities from blink.cmp
            local capabilities = blink.get_lsp_capabilities()

            -- IMPORTANT: Fix Position Encodings Warning
            -- Force UTF-16 to avoid conflicts between clangd and other servers.
            capabilities.offsetEncoding = { "utf-16" }

            -- Define how each server should be set up
            mlsp.setup_handlers({
                -- Default handler
                function(server_name)
                    lspconfig[server_name].setup({ capabilities = capabilities })
                end,

                -- Optimized Clangd setup
                ["clangd"] = function()
                    require("clangd_extensions").setup({
                        server = {
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
                                "--function-arg-placeholders",
                            },
                        },
                        extensions = { autoSetHints = true, inlay_hints = { inline = false } },
                    })
                end,

                -- Optimized Lua setup
                ["lua_ls"] = function()
                    lspconfig.lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                diagnostics = { globals = { "vim" } },
                                workspace = { checkThirdParty = false },
                            },
                        },
                    })
                end,
            })
        end,
    },

    -- Core LSP Plugin
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp", "p00f/clangd_extensions.nvim" },
        config = function()
            -- Rounded borders for LSP documentation windows
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
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

    -- Sticky header showing the context (function/class) you are currently in.
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

    -- Improved Diagnostic & Quickfix UI (Trouble.nvim)
    {
        "folke/trouble.nvim",
        cmd = { "Trouble" },
        opts = { modes = { lsp = { win = { position = "right" } } } },
    },

    -- Highlight and search TODO/FIXME comments
    {
        "folke/todo-comments.nvim",
        event = "BufReadPost",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", alt = { "OPTIM" } },
                NOTE = { icon = " ", color = "hint" },
                TEST = { icon = "⏲ ", color = "test" },
            },
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
