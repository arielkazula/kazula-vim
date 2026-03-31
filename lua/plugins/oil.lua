-- plugins/oil.lua --------------------------------------------------------
return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      columns = { "icon", "permissions", "size", "mtime" },
      buf_options = { buflisted = false, bufhidden = "hide" },
      win_options = { wrap = false, signcolumn = "no", cursorcolumn = false, foldcolumn = "0", spell = false, list = false, conceallevel = 3, concealcursor = "nvic" },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = true,
      view_options = { show_hidden = true, is_hidden_file = function(name, bufnr) return vim.startswith(name, ".") end, is_always_hidden_file = function(name, bufnr) return false end, sort = { { "type", "asc" }, { "name", "asc" } } },
      float = { padding = 2, max_width = 0, max_height = 0, border = "rounded", win_options = { winblend = 0 } },
      preview = { max_width = 0.9, min_width = 0.4, width = nil, max_height = 0.9, min_height = 0.4, height = nil, border = "rounded", win_options = { winblend = 0 } },
      progress = { max_width = 0.9, min_width = 0.4, width = nil, max_height = 0.9, min_height = 0.4, height = nil, border = "rounded", win_options = { winblend = 0 } },
    },
  },
}
