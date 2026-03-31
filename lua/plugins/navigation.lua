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
      require("fzf-lua").register_ui_select()
    end,
  },

  -- Jump anywhere on the screen with 's' (Flash.nvim)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm",
      search = { mode = "search" },
      modes = { char = { enabled = true } },
    },
  },

  -- Floating file explorer (Oil.nvim)
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

  -- Intuitive split management (smart-splits.nvim)
  -- Navigates seamlessly between splits and supports resizing with Meta keys.
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {
        ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
        ignored_buftypes = { 'nofile' },
    },
  },
}
