-- core/options.lua -------------------------------------------------------
local o                    = vim.opt
o.signcolumn               = "yes"
o.wrap                     = false
o.smartindent              = true
o.ignorecase               = true
o.smartcase                = true
o.updatetime               = 250
o.termguicolors            = true
o.splitbelow, o.splitright = true, true


-- settings.lua
o.number = true          -- Show line numbers
o.relativenumber = false -- Show relative line numbers
o.hlsearch = true        -- Highlight search results
o.expandtab = true       -- Convert tabs to spaces
o.shiftwidth = 4         -- Indentation width
o.tabstop = 4            -- Tab width
o.clipboard = "unnamedplus"
o.textwidth = 80
o.wrapmargin = 0
o.colorcolumn = "80"
o.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
vim.opt.termguicolors = true
vim.diagnostic.config({
    virtual_text = false,
    underline = false,
    signs = true,
    severity_sort = true,
})


-- Searching
o.hlsearch = false  -- do not highlight all search matches:contentReference[oaicite:12]{index=12}
o.ignorecase = true -- ignore case in search patterns...
o.smartcase = true  -- ...unless uppercase letter is used (smart case):contentReference[oaicite:13]{index=13}

-- Indentation and tabs
o.expandtab = true   -- use spaces instead of tabs
o.shiftwidth = 4     -- indent by 4 spaces (adjust per preference/project)
o.tabstop = 4        -- 1 tab = 4 spaces visually
o.softtabstop = 4    -- <Tab> in insert mode inserts 4 spaces

o.breakindent = true -- enable break-indent (wrapped lines keep indent):contentReference[oaicite:14]{index=14}
o.linebreak = true   -- wrap long lines at convenient points
o.showmatch = true   -- highlight matching bracket

-- Misc
o.mouse = "a"                    -- enable mouse support (all modes):contentReference[oaicite:19]{index=19}
o.scrolloff = 5                  -- keep 5 lines above/below cursor when scrolling
o.fileencoding = "utf-8"         -- file encoding
o.backspace = "indent,eol,start" -- make backspace behave in a sane way


-- Undo and backup
o.undofile = true  -- save undo history to file (persistent undo):contentReference[oaicite:15]{index=15}
o.swapfile = false -- don't use swap files
