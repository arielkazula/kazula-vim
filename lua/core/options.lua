-- core/options.lua -------------------------------------------------------
local o = vim.opt

-- Appearance
o.termguicolors  = true
o.number         = true          -- Show line numbers
o.relativenumber = false         -- Show relative line numbers
o.signcolumn     = "yes"         -- Always show sign column
o.cursorline     = true          -- Highlight the current line
o.guicursor      = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
o.colorcolumn    = "80"
o.showmatch      = true          -- Highlight matching bracket

-- Indentation & Tabs
o.expandtab      = true          -- Convert tabs to spaces
o.shiftwidth     = 4             -- Indentation width
o.tabstop        = 4             -- Tab width
o.softtabstop    = 4             -- <Tab> in insert mode inserts 4 spaces
o.smartindent    = true
o.breakindent    = true          -- Wrapped lines keep indent
o.linebreak      = true          -- Wrap long lines at convenient points

-- Search
o.ignorecase     = true          -- Ignore case in search patterns
o.smartcase      = true          -- ...unless uppercase letter is used
o.hlsearch       = false         -- Do not highlight all search matches

-- Behavior
o.wrap           = false
o.updatetime     = 250           -- Faster completion and diagnostics
o.mouse          = "a"           -- Enable mouse support
o.scrolloff      = 5             -- Keep 5 lines above/below cursor
o.fileencoding   = "utf-8"
o.backspace      = "indent,eol,start"
o.clipboard      = "unnamedplus" -- Use system clipboard

-- Windows
o.splitbelow     = true          -- Put new windows below current
o.splitright     = true          -- Put new windows right of current

-- Undo & Backup
o.undofile       = true          -- Persistent undo
o.swapfile       = false         -- Don't use swap files

-- Diagnostics Configuration (Modern 2025 Icons) --------------------------
local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = signs.Error,
            [vim.diagnostic.severity.WARN]  = signs.Warn,
            [vim.diagnostic.severity.HINT]  = signs.Hint,
            [vim.diagnostic.severity.INFO]  = signs.Info,
        },
    },
    virtual_text = {
        prefix = "●",
        source = "if_many",
        spacing = 4,
    },
    underline = true,
    severity_sort = true,
    float = {
        border = "rounded",
        source = "always",
    },
})
