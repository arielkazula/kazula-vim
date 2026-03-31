-- lua/core/autocmds.lua --------------------------------------------------
-- This file contains all automated behaviors and autocommands for a 
-- smoother development experience.

local function augroup(name)
  return vim.api.nvim_create_augroup("kazula_" .. name, { clear = true })
end

-- 1. Highlight on yank ---------------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- 2. LSP & Diagnostics ---------------------------------------------------
vim.api.nvim_create_autocmd("CursorHold", {
  group = augroup("lsp_diagnostics"),
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false })
  end,
})

-- 3. Buffer behavior -----------------------------------------------------
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(current_tab)
  end,
})

-- Go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].kazula_last_loc then
      return
    end
    vim.b[buf].kazula_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
