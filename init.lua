-- init.lua ---------------------------------------------------------------
-- Kick-start Neovim with lazy.nvim.
-- This configuration is modular, performant, and documented for 2025.

-- Set leaders before any plugins are loaded
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- ── 1. Bootstrap lazy.nvim ──────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── 2. Core Configurations ──────────────────────────────────────────────
-- Load options, autocommands, and keymaps.
require("core.options")   -- Basic editor settings
require("core.autocmds")  -- Automated behaviors (yank highlight, etc.)

-- ── 3. Plugin Setup ─────────────────────────────────────────────────────
-- Setup plugins (located in lua/plugins/*.lua)
require("lazy").setup("plugins", {
  ui = { border = "rounded" },           -- Use rounded borders for Lazy UI
  change_detection = { notify = false }, -- Silently reload config on changes
  performance = {
    rtp = {
      -- Disable unused built-in plugins for faster startup
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Load global keymaps after plugins are initialized
require("core.keymaps")
