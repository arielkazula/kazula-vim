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
            local packages = { "clang-format", "jq", "black", "codespell", "shfmt" }
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
            automatic_enable = false,
        },
        config = function(_, opts)
            local mlsp = require("mason-lspconfig")
            mlsp.setup(opts)

            local capabilities = require("blink.cmp").get_lsp_capabilities()
            capabilities.offsetEncoding = { "utf-16" }

            -- Set global defaults (No global root_dir blocker here)
            if vim.lsp.config then
                vim.lsp.config("*", { 
                    capabilities = capabilities,
                    --- Fix the "File URL host must be 'localhost' or empty on linux" error.
                    --- This is common in WSL, remote SSH, or containers where the hostname 
                    --- is injected into the rootUri, causing servers like clangd to fail.
                    on_new_config = function(config, root_dir)
                        if config.root_uri or root_dir then
                            local uri = config.root_uri or vim.uri_from_fname(root_dir)
                            -- Strip the hostname: file://hostname/path -> file:///path
                            config.root_uri = uri:gsub("file://[^/]+/", "file:///")
                        end
                    end,
                })
            end

            -- Server-specific overrides using native vim.lsp.config
            vim.lsp.config("clangd", {
                filetypes = { "c", "cpp", "cc", "h", "hpp", "objc", "objcpp", "cuda", "proto" },
                root_markers = { ".git", "compile_commands.json", ".clangd" },
                cmd = {
                    "clangd", "-j=12", "--background-index", "--background-index-priority=normal",
                    "--clang-tidy", "--all-scopes-completion", "--completion-style=detailed",
                    "--header-insertion=never", "--fallback-style=llvm", "--offset-encoding=utf-16",
                    "--function-arg-placeholders=true", "--enable-config", "--malloc-trim", "--pch-storage=disk",
                    "--limit-results=0", "--header-insertion-decorators=false",
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

            vim.lsp.config("harper_ls", {
                -- Explicitly restrict filetypes to prevent harper from attaching to oil://
                filetypes = { "markdown", "text", "html", "gitcommit", "cpp", "c", "lua", "python", "sh" },
                settings = {
                    ["harper-ls"] = {
                        workspaceDictPath = "./spell/dictionary.txt",
                        dialect = "American",
                        linters = {
                            spell_check = true,
                            SentenceCapitalization = false,
                            LongSentences = false,
                            SpelledNumbers = false,
                            ExpandParameter = false,
                        },
                        codeActions = { ForceStable = true },
                        diagnosticSeverity = "hint",
                    },
                },
            })

            --- Activates an LSP server only for its supported file types and on real files.
            --- This prevents crashes on virtual file systems (like oil://) and 
            --- avoids unnecessary LSP overhead in unrelated buffers.
            --- @param server_name string The name of the LSP server to enable.
            local function safe_enable_lsp_server(server_name)
                -- Retrieve the server's configuration from nvim-lspconfig to get supported filetypes.
                local server_config = require("lspconfig.configs")[server_name]
                -- Default to an empty list if not found to avoid enabling on everything.
                local supported_filetypes = (server_config and server_config.filetypes) or {}

                vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
                    pattern = "*",
                    callback = function(event_args)
                        local buffer_number = event_args.buf
                        local buffer_uri = vim.uri_from_bufnr(buffer_number)
                        local current_buffer_filetype = vim.bo[buffer_number].filetype

                        -- Explicitly ignore Oil buffers and other virtual filesystems.
                        if current_buffer_filetype == "oil" or not buffer_uri:match("^file://") then
                            return
                        end

                        -- Only enable if the current filetype is in the server's supported list.
                        -- We avoid using "*" here to stay "safe" against virtual buffer leaks.
                        local is_supported = vim.tbl_contains(supported_filetypes, current_buffer_filetype)

                        if is_supported then
                            vim.lsp.enable(server_name)
                        end
                    end,
                })
            end

            for _, server_name in ipairs(mlsp.get_installed_servers()) do
                safe_enable_lsp_server(server_name)
            end
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
            
            require("clangd_extensions").setup({
                extensions = { autoSetHints = true, inlay_hints = { inline = false } },
                symbol_info = { border = "rounded" },
                ast = {
                    role_icons = {
                        type = "",
                        declaration = "",
                        expression = "",
                        statement = "",
                        specifier = "",
                        ["template argument"] = "",
                    },
                    kind_icons = {
                        Compound = "",
                        Recovery = "",
                        TranslationUnit = "",
                        PackExpansion = "",
                        TemplateTypeParm = "",
                        TemplateTemplateParm = "",
                        TemplateParamObject = "",
                    },
                },
                memory_usage = { border = "rounded" },
            })
        end,
    },

    -- Advanced Syntax Highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        opts = {
            ensure_installed = {
                "bash", "json", "lua", "markdown", "markdown_inline",
                "python", "regex", "vim", "cpp", "c", "vimdoc",
            },
            highlight = { 
                enable = true,
                additional_vim_regex_highlighting = false,
            },
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
                c = { template = { annotation_convention = "doxygen" } },
                cpp = { template = { annotation_convention = "doxygen" } },
                python = { template = { annotation_convention = "google_docstrings" } },
                lua = { template = { annotation_convention = "ldoc" } },
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
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            sign_priority = 8,
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
            },
            gui_style = { fg = "NONE", bg = "BOLD" },
            colors = {
                error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
                info = { "DiagnosticInfo", "#2563EB" },
                hint = { "DiagnosticHint", "#10B981" },
                default = { "Identifier", "#7C3AED" },
                test = { "Identifier", "#FF00FF" },
            },
        },
    },
}
