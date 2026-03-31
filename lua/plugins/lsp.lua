-- lua/plugins/lsp.lua ----------------------------------------------------
-- This file manages LSP and Treesitter with specialized fixes for 
-- oil.nvim and Linux URI strictness.

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
            -- Disable automatic_enable to prevent crashing on non-file URIs (oil://)
            automatic_enable = false,
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local mlsp = require("mason-lspconfig")
            mlsp.setup(opts)

            local capabilities = require("blink.cmp").get_lsp_capabilities()
            capabilities.offsetEncoding = { "utf-16" }

            -- Global guard for all servers to prevent them from starting on oil buffers
            -- This prevents the "File URL host must be localhost" error on Linux.
            local function safe_setup(server_name, config)
                config = config or {}
                config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
                
                -- Guard: Disable the server if the root_dir or URI belongs to oil.nvim
                local original_on_new_config = config.on_new_config
                config.on_new_config = function(new_config, new_root_dir)
                    if new_root_dir and (new_root_dir:match("^oil:") or new_root_dir:match("^%w+://")) then
                        new_config.enabled = false
                    end
                    if original_on_new_config then
                        original_on_new_config(new_config, new_root_dir)
                    end
                end

                lspconfig[server_name].setup(config)
            end

            -- Setup servers with specific configs
            safe_setup("clangd", {
                cmd = {
                    "clangd", "-j=4", "--background-index", "--clang-tidy",
                    "--completion-style=detailed", "--header-insertion=never",
                    "--fallback-style=llvm", "--offset-encoding=utf-16",
                    "--function-arg-placeholders=true",
                },
            })

            safe_setup("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                    },
                },
            })

            safe_setup("harper_ls", {
                settings = {
                    ["harper-ls"] = { linters = { spell_check = true } },
                },
            })

            -- Setup all other Mason-installed servers automatically
            for _, server in ipairs(mlsp.get_installed_servers()) do
                if not vim.tbl_contains({ "clangd", "lua_ls", "harper_ls" }, server) then
                    safe_setup(server)
                end
            end
        end,
    },

    -- 3. Core LSP Plugin: Global UI
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp", "p00f/clangd_extensions.nvim" },
        config = function()
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
            
            require("clangd_extensions").setup({
                extensions = { autoSetHints = true, inlay_hints = { inline = false } },
            })
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

    -- Neogen
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

    -- Trouble
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
