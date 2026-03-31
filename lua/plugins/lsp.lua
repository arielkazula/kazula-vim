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

            -- Set global defaults
            if vim.lsp.config then
                vim.lsp.config("*", { capabilities = capabilities })
            end

            -- Server-specific overrides
            vim.lsp.config("clangd", {
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto", "cc", "h" },
                root_markers = {
                    ".clangd", ".clang-tidy", ".clang-format",
                    "compile_commands.json", "compile_flags.txt",
                    "configure.ac", ".git",
                },
                cmd = {
                    "clangd",
                    "-j=4",
                    "--background-index",
                    "--background-index-priority=background",
                    "--clang-tidy",
                    "--all-scopes-completion",
                    "--completion-style=detailed",
                    "--header-insertion=never",
                    "--fallback-style=llvm",
                    "--offset-encoding=utf-16",
                    "--function-arg-placeholders=true",
                    "--enable-config",
                    "--malloc-trim",
                    "--pch-storage=disk",
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

            -- Specialized Harper configuration
            vim.lsp.config("harper_ls", {
                settings = {
                    ["harper-ls"] = {
                        workspaceDictPath = "./spell/dictionary.txt",
                        dialect = "American",
                        linters = {
                            spell_check = true,
                            SentenceCapitalization = false,
                            LongSentences = false,
                            SpelledNumbers = false,
                        },
                        codeActions = { ForceStable = true },
                        diagnosticSeverity = "hint",
                    },
                },
            })

            -- Safe enabler
            local function safe_enable(server)
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = "*",
                    callback = function(args)
                        local uri = vim.uri_from_bufnr(args.buf)
                        if uri:match("^file://") then
                            vim.lsp.enable(server)
                        end
                    end,
                })
            end

            for _, server in ipairs(mlsp.get_installed_servers()) do
                safe_enable(server)
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
            })
        end,
    },

    -- CMake Support (Professional C++ Development)
    -- This makes Neovim behave like CLion/VS.
    {
        "Civitasv/cmake-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            cmake_command = "cmake",
            cmake_build_directory = "build/${variant:buildType}", -- Logic for Release/Debug splits
            cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
            cmake_build_options = {},
            cmake_console_size = 10,
            cmake_show_console = "always",
            cmake_dap_configuration = { name = "cpp", type = "lldb", request = "launch" },
            cmake_variants_message = {
                short = { show = true },
                long = { show = true, max_length = 40 },
            },
        },
    },

    -- Advanced Refactoring (Extract Function, Inline Variable, etc.)
    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
        opts = {},
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
            highlight = { enable = true, additional_vim_regex_highlighting = false },
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
                cs = { template = { annotation_convention = "doxygen" } },
                c = {
                    template = {
                        annotation_convention = "custom",
                        custom = {
                            { nil, "/**", { no_results = true, type = { "func", "file", "type" } } },
                            { nil, " * @file", { no_results = true, type = { "file" } } },
                            { nil, " * $1", { no_results = true, type = { "func", "file", "type" } } },
                            { nil, " */", { no_results = true, type = { "func", "file", "type" } } },
                            { nil, "" },
                            { nil, "/**", { type = { "func", "type" } } },
                            { nil, " * @brief $1", { type = { "func", "type" } } },
                            { "parameters", " * @param %s $1" },
                            { "return_statement", " * @return $1" },
                            { nil, " */" },
                        },
                    },
                },
                cpp = {
                    template = {
                        annotation_convention = "custom",
                        custom = {
                            { nil, "/**", { no_results = true, type = { "func", "file", "class" } } },
                            { nil, " * @file", { no_results = true, type = { "file" } } },
                            { nil, " * $1", { no_results = true, type = { "func", "file", "class" } } },
                            { nil, " */", { no_results = true, type = { "func", "file", "class" } } },
                            { nil, "" },
                            { nil, "/**", { type = { "func", "class" } } },
                            { nil, " * @brief $1", { type = { "func", "class" } } },
                            { "tparam", " * @tparam %s $1" },
                            { "parameters", " * @param %s $1" },
                            { "return_statement", " * @return $1" },
                            { nil, " */" },
                        },
                    },
                },
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
