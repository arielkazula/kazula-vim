-- lua/plugins/lsp.lua ----------------------------------------------------
-- LSP servers, tooling, diagnostics, AI completion, and documentation.

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
            local packages = {
                -- Formatters (used by conform.nvim)
                "clang-format", "jq", "black", "shfmt", "prettier", "stylua",
                -- Linters / misc tools
                "codespell",
                -- Copilot LSP (inline completion + NES)
                "copilot-language-server",
            }
            for _, tool in ipairs(packages) do
                local p = mr.get_package(tool)
                if not p:is_installed() then p:install() end
            end
        end,
    },

    -- 2. Mason-LSPConfig: Bridges Mason with native LSP (Neovim 0.11+ API)
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            ensure_installed = {
                "clangd", "bashls", "pyright", "cmake",
                "lua_ls", "marksman", "jsonls",
            },
            -- calls vim.lsp.enable() per installed server; "copilot" excluded
            -- because copilot-lsp enables "copilot_ls" for the same binary.
            automatic_enable = { exclude = { "copilot" } },
        },
        config = function(_, opts)
            local mlsp = require("mason-lspconfig")
            mlsp.setup(opts)

            -- Global capabilities (shared by all servers)
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            vim.lsp.config("*", { capabilities = capabilities })

            -- clangd needs its own capabilities with utf-16 offset encoding;
            -- setting this globally would confuse pyright, lua_ls, etc.
            local clangd_caps = vim.tbl_deep_extend("force", capabilities, {
                offsetEncoding = { "utf-16" },
            })
            vim.lsp.config("clangd", {
                capabilities = clangd_caps,
                filetypes = { "c", "cpp", "cc", "h", "hpp", "objc", "objcpp", "cuda", "proto" },
                root_markers = { ".git", "compile_commands.json", ".clangd" },
                cmd = {
                    "clangd", "-j=6", "--background-index", "--background-index-priority=normal",
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
                        workspace = { checkThirdParty = false },
                    },
                },
            })
        end,
    },

    -- 3. Core LSP Plugin
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "p00f/clangd_extensions.nvim" },
        config = function()
            -- Format-on-save is handled by conform.nvim (see plugins/tools.lua).
            -- clangd_extensions.setup() registers its own LspAttach internally
            -- via autoSetHints = true; no manual callback needed here.
            require("clangd_extensions").setup({
                extensions = { autoSetHints = true, inlay_hints = { inline = false } },
                symbol_info = { border = "rounded" },
                ast = {
                    role_icons = {
                        type = "",
                        declaration = "",
                        expression = "",
                        statement = "",
                        specifier = "",
                        ["template argument"] = "",
                    },
                    kind_icons = {
                        Compound = "",
                        Recovery = "",
                        TranslationUnit = "",
                        PackExpansion = "",
                        TemplateTypeParm = "",
                        TemplateTemplateParm = "",
                        TemplateParamObject = "",
                    },
                },
                memory_usage = { border = "rounded" },
            })
        end,
    },

    -- 4. Documentation Generator (Neogen)
    {
        "danymat/neogen",
        cmd = "Neogen",
        opts = {
            enabled = true,
            languages = {
                c      = { template = { annotation_convention = "doxygen" } },
                cpp    = { template = { annotation_convention = "doxygen" } },
                python = { template = { annotation_convention = "google_docstrings" } },
                lua    = { template = { annotation_convention = "ldoc" } },
            },
        },
    },

    -- 5. Improved Diagnostic UI (Trouble)
    {
        "folke/trouble.nvim",
        cmd = { "Trouble" },
        opts = { modes = { lsp = { win = { position = "right" } } } },
    },

    -- 6. Todo comments
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            sign_priority = 8,
            keywords = {
                FIX      = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO     = { icon = " ", color = "info" },
                HACK     = { icon = " ", color = "warning" },
                WARN     = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF     = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE     = { icon = " ", color = "hint", alt = { "INFO" } },
                TEST     = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
                REFACTOR = { icon = " ", color = "warning", alt = { "REWRITE", "CLEAN" } },
                DOCS     = { icon = "󰈙 ", color = "info", alt = { "DOC", "DOCUMENTATION" } },
                DEBUG    = { icon = " ", color = "error", alt = { "DEBUGGING" } },
            },
            gui_style = { fg = "NONE", bg = "BOLD" },
            colors = {
                error   = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
                info    = { "DiagnosticInfo", "#2563EB" },
                hint    = { "DiagnosticHint", "#10B981" },
                default = { "Identifier", "#7C3AED" },
                test    = { "Identifier", "#FF00FF" },
            },
        },
    },

    -- 7. AI: Copilot via copilot_ls
    --    * Insert-mode ghost text: native vim.lsp.inline_completion (0.12+),
    --      accept with <M-l> (core/keymaps.lua). <Tab> belongs to blink.cmp.
    --    * Next Edit Suggestions: copilot-lsp, normal-mode <Tab>.
    {
        "copilotlsp-nvim/copilot-lsp",
        init = function()
            vim.g.copilot_nes_debounce = 500
            vim.lsp.enable("copilot_ls")
            vim.lsp.inline_completion.enable()
            -- Tab in normal mode: jump to/apply NES suggestion; fall back to <C-i>.
            vim.keymap.set("n", "<tab>", function()
                local state = vim.b[vim.api.nvim_get_current_buf()].nes_state
                if state then
                    local nes = require("copilot-lsp.nes")
                    local _ = nes.walk_cursor_start_edit()
                        or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
                    return nil
                end
                return "<C-i>"
            end, { desc = "Copilot NES: accept suggestion", expr = true })
        end,
    },
}
