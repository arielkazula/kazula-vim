-- File: lua/mason.lua
-- 1. Bootstrap Mason
require("mason").setup()

local lspconfig = require("lspconfig")
local blink_cmp = require("blink.cmp")

-- Shared LSP capabilities from blink.cmp
local capabilities = blink_cmp.get_lsp_capabilities()

-- 2. Server-specific configurations
local server_opts = {
  clangd = {
    cmd = {
      "clangd",
      "--header-insertion=never",
      "--all-scopes-completion",
      "--background-index",
      "--pch-storage=disk",
      "--log=info",
      "--completion-style=detailed",
      "--enable-config",
      "--clang-tidy",
      "--offset-encoding=utf-16",
      "--fallback-style=llvm",
      "--function-arg-placeholders=1",
      "-j=8",

    },
    on_init = function(client)
      -- Ensure offset encoding is UTF-8 for better compatibility
      client.offset_encoding = "utf-8"
    end,
  },
  harper_ls = {
    settings = {
      ["harper-ls"] = {
        linters = {
          spell_check = true,
          -- ... your other harper-ls settings ...
        },
      },
    },
  },
}

-- 3. Setup mason-lspconfig with correct handler approach
require("mason-lspconfig").setup({
  ensure_installed = {
    "clangd", "bashls", "pyright", "cmake",
    "lua_ls", "harper_ls", "marksman", "jsonls",
  },
  automatic_installation = true,
})

-- Use the recommended v2+ config: configure each server via vim.lsp.config
for _, server in ipairs(require("mason-lspconfig").get_installed_servers()) do
  local opts = {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      -- common on_attach (e.g., diagnostic keymaps, formatting on save, etc.)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
        })
      end
    end,
  }

  -- Merge any server-specific overrides
  if server_opts[server] then
    opts = vim.tbl_deep_extend("force", opts, server_opts[server])
  end

  -- Finally register the server
  vim.lsp.config(server, opts)
end

-- 4. Install formatter tools via Mason
local registry = require("mason-registry")
for _, pkg in ipairs({ "clang-format", "jq", "black", "codespell" }) do
  local p = registry.get_package(pkg)
  if not p:is_installed() then p:install() end
end

-- 5. Blink.cmp formatting integration (auto-format)
require("blink.cmp").setup({
  formatters = {
    ensure_installed = { "clang-format", "jq", "black", "codespell" },
    setup = {
      cpp    = { "clang-format" },
      json   = { "jq" },
      python = { "black", "isort" }
    },
    format_on_save = true,
  },
})

