-- init.lua ---------------------------------------------------------------
-- Kick-start Neovim with lazy.nvim (no LazyVim).

vim.g.mapleader      = " "
vim.g.maplocalleader = " "


-- ── bootstrap lazy.nvim ────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("core.options")
-- Setup plugins (see plugins.lua for the plugin definitions)
require("lazy").setup("plugins", {
  ui = { border = "rounded" },           -- nice border for Lazy UI
  change_detection = { notify = false }, -- don't spam notifications on config change
})

require("core.keymaps")
require("core.lspOptions")