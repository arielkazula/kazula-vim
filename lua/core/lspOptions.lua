-- File: lua/mason.lua
-- 1. Bootstrap Mason
require("mason").setup()

local lspconfig = require("lspconfig")
local blink_cmp = require("blink.cmp")

-- 1. Shared LSP capabilities from blink.cmp
local capabilities = blink_cmp.get_lsp_capabilities()

-- 2. Server-specific configurations
local server_opts = {
    clangd = {
        cmd = {
            "clangd",
            "-j=4", -- Throttles background workers to prevent CPU exhaustion
            "--background-index",
            "--background-index-priority=background",
            "--clang-tidy",
            "--completion-style=detailed",
            "--enable-config",
            "--fallback-style=llvm",
            "--header-insertion=never",
            "--log=info",
            "--malloc-trim",
            "--pch-storage=disk",
            "--offset-encoding=utf-8", -- Match Neovim's native encoding
        },
        on_init = function(client)
            -- Ensure Neovim handles the offset encoding correctly
            client.offset_encoding = "utf-8"
        end,
    },
    harper_ls = {
        settings = {
            ["harper-ls"] = {
                linters = {
                    spell_check = true,
                },
            },
        },
    },
}

-- 3. Setup mason-lspconfig
require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd", "bashls", "pyright", "cmake",
        "lua_ls", "harper_ls", "marksman", "jsonls", "cspell_ls",
    },
    automatic_installation = true,
})

-- 4. Configure and register each server
for _, server in ipairs(require("mason-lspconfig").get_installed_servers()) do
    local opts = {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
            -- Format on save with a strict timeout to prevent deadlocks
            if client.supports_method("textDocument/formatting") then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format({
                            bufnr = bufnr,
                            async = false,
                            timeout_ms = 1000 -- Give up after 1s if clangd hangs
                        })
                    end,
                })
            end
        end,
    }

    -- Merge any server-specific overrides (like our clangd settings)
    if server_opts[server] then
        opts = vim.tbl_deep_extend("force", opts, server_opts[server])
    end

    -- Register the server
    vim.lsp.config(server, opts)
end

-- 5. Install external tools via Mason
local registry = require("mason-registry")
local external_tools = { "clang-format", "jq", "black", "codespell" }

for _, pkg in ipairs(external_tools) do
    local p = registry.get_package(pkg)
    if not p:is_installed() then
        p:install()
    end
end

-- 6. Setup blink.cmp
require("blink.cmp").setup({
    -- Add your actual completion settings here.
    -- (The previous 'formatters' block was removed because blink.cmp
    -- is exclusively for completion, not formatting).
})

vim.cmd("FzfLua register_ui_select")
