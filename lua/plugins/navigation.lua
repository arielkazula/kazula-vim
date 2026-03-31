-- lua/plugins/navigation.lua ---------------------------------------------
-- This file contains plugins for fuzzy finding, file exploration, 
-- and jumping between text (motions).

return {
  -- High-performance fuzzy finder (FZF-Lua)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    opts = {},
    config = function(_, opts)
      require("fzf-lua").setup(opts)
      require("fzf-lua").register_ui_select() -- Make fzf handle vim.ui.select
    end,
  },

  -- Jump anywhere on the screen with 's' (Flash.nvim)
  -- Replaces standard / and ? search with a faster jumping mechanism.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm", -- Keys to use for jump markers
      search = { mode = "search" },          -- Integration with regular search
      modes = {
        char = { enabled = true },           -- Enhance f, F, t, T motions
      },
    },
  },

  -- Floating file explorer that lets you edit your filesystem as a buffer
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      columns = { "icon", "permissions", "size", "mtime" },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      float = { border = "rounded" },
      view_options = { show_hidden = true },
    },
  },
}
