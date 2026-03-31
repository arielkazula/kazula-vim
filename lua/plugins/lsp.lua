-- lua/plugins/lsp.lua ----------------------------------------------------
-- This file manages LSP and Treesitter using Neovim 0.11+ native APIs.

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
            -- Disable automatic_enable so we can use a safe wrapper
            automatic_enable = false,
        },
        config = function(_, opts)
            local mlsp = require("mason-lspconfig")
            mlsp.setup(opts)

            local capabilities = require("blink.cmp").get_lsp_capabilities()
            capabilities.offsetEncoding = { "utf-16" }

            -- Set global defaults for ALL servers
            if vim.lsp.config then
                vim.lsp.config("*", { capabilities = capabilities })
            end

            -- Server-specific overrides using native vim.lsp.config
            -- We use 'root_markers' which is the 0.11+ way to define project roots.
            vim.lsp.config("clangd", {
                root_markers = { ".git", "compile_commands.json", "build", "CMakeLists.txt" },
                cmd = {
                    "clangd", "-j=4", "--background-index", "--clang-tidy",
                    "--completion-style=detailed", "--header-insertion=never",
                    "--fallback-style=llvm", "--offset-encoding=utf-16",
                    "--function-arg-placeholders=true",
                },
            })

            vim.lsp.config("lua_ls", {
                root_markers = { ".luarc.json", ".git", "init.lua" },
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                    },
                },
            })

            -- A safe enabler that ignores oil:// and other non-file buffers
            -- to prevent the "File URL host" error on Linux.
            local function safe_enable(server)
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = "*",
                    callback = function(args)
                        local buf = args.buf
                        local uri = vim.uri_from_bufnr(buf)
                        if not uri:match("^file://") then
                            return
                        end
                        -- Only enable if the server supports this filetype (logic handled by core)
                        vim.lsp.enable(server)
                    end,
                })
            end

            -- Enable all installed servers safely
            for _, server in ipairs(mlsp.get_installed_servers()) do
                safe_enable(server)
            end
        end,
    },

    -- 3. Core LSP Plugin: Handlers and UI
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
