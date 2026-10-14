-- lua/plugins/navigation.lua ---------------------------------------------
-- This file contains plugins for fuzzy finding, file exploration, 
-- and project navigation.

-- True if `path` is tracked by git (Oil then uses git mv / git rm).
local function is_tracked(path)
  local res = vim.system(
    { "git", "ls-files", "--error-unmatch", path },
    { cwd = vim.fs.dirname(path) }
  ):wait()
  return res.code == 0
end

return {
  -- High-performance fuzzy finder (FZF-Lua)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    init = function()
      -- fzf-lua is lazy-loaded; install a stub so the first vim.ui.select()
      -- call loads it, registers its picker, and forwards the call.
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "fzf-lua" } })
        return vim.ui.select(...)
      end
    end,
    opts = {
        prompt = "  ",
        winopts = {
            height = 0.85,
            width = 0.80,
            border = "rounded",
            preview = {
                hidden = "nohidden",
                vertical = "up:45%",
                horizontal = "right:50%",
                layout = "flex",
            },
        },
        fzf_opts = { ["--tiebreak"] = "begin" },
        -- Simplify UI but keep hints for guidance
        hls = { border = "FloatBorder" },
        keymap = {
            fzf = {
                ["ctrl-q"] = "select-all+accept",
            },
        },
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
    lazy = false, -- needed for `nvim .` / `:e dir/` (netrw is disabled)
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
      watch_for_changes = true, -- refresh listing when files change on disk
      float = { border = "rounded" },
      win_options = {
        -- Show the current directory path at the top of the Oil window
        winbar = "%!v:lua.require('oil').get_current_dir()",
        signcolumn = "yes:2", -- room for oil-git-status (index + worktree)
      },
      -- Tracked files: rename/move → git mv, delete → git rm.
      -- New files are never auto-staged. Keymaps live in core/keymaps.lua.
      git = {
        add = function() return false end,
        mv = function(src) return is_tracked(src) end,
        rm = function(path) return is_tracked(path) end,
      },
      -- Free <C-h>/<C-l> for smart-splits; splits use <C-v>/<C-x> (keymaps.lua)
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-s>"] = false,
      },
      view_options = { show_hidden = true },
    },
  },

  -- Git status per entry in Oil's sign column
  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    lazy = false,
    opts = {},
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
