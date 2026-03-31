-- lua/plugins/navigation.lua ---------------------------------------------
-- This file contains plugins for fuzzy finding, file exploration, 
-- and project navigation.

return {
  -- High-performance fuzzy finder (FZF-Lua)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    opts = {
        winopts = {
            height = 0.85,
            width = 0.80,
            preview = {
                hidden = "nohidden",
                vertical = "up:45%",
                horizontal = "right:50%",
                layout = "flex",
            },
        },
        fzf_opts = { ["--tiebreak"] = "begin" },
    },
    config = function(_, opts)
      require("fzf-lua").setup(opts)
      require("fzf-lua").register_ui_select()
    end,
  },

  -- Harpoon2
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        settings = {
            save_on_toggle = true,
            sync_on_ui_close = true,
        },
    },
    config = function(_, opts)
        require("harpoon").setup(opts)
    end,
  },

  -- Flash.nvim
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
      -- Refined icon configuration for 2025
      columns = {
        {
          "icon",
          default_file = "󰈚 ",
          directory = "󰉋 ",
          add_padding = false,
        },
      },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      float = { border = "rounded" },
      view_options = { show_hidden = true },
    },
  },

  -- Intuitive split management (smart-splits.nvim)
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {
        ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
        ignored_buftypes = { 'nofile' },
    },
  },
}
