-- lua/core/keymaps.lua ---------------------------------------------------
-- The Central Source of Truth for all keybindings in the project.
-- Uses `which-key.nvim` (v3+) for intuitive grouping and discovery.

local wk = require("which-key")

-- 1. Helper Functions ----------------------------------------------------
_G.CopyFilePathAndLine = function()
    local filepath = vim.fn.expand("%")
    local line_number = vim.fn.line(".")
    local result = filepath .. ":" .. line_number
    vim.fn.setreg("+", result)
    print("Copied: " .. result)
end

local function goto_next_diagnostic(severity)
    vim.diagnostic.goto_next({ severity = severity, wrap = true })
end
local function goto_prev_diagnostic(severity)
    vim.diagnostic.goto_prev({ severity = severity, wrap = true })
end

-- 2. Which-Key Mappings --------------------------------------------------

wk.add({
    -- Navigation (Flash.nvim)
    { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash Jump" },
    { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash Treesitter" },
    { "r", function() require("flash").remote() end, mode = "o", desc = "Remote Flash" },
    { "R", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "Treesitter Search" },
    { "<c-s>", function() require("flash").toggle() end, mode = "c", desc = "Toggle Flash Search" },

    -- Core / General
    { "<leader><Bar>", ":vsplit<cr>", desc = "Split Screen Vertical" },
    { "<leader>_ ", ":split<cr>", desc = "Split Screen Horizontal" },
    { "<A-[>", ":bprevious<CR>", desc = "Previous Buffer" },
    { "<A-]>", ":bnext<CR>", desc = "Next Buffer" },
    { "<leader>cc", ":lua CopyFilePathAndLine()<CR>", desc = "Copy File Path and Line" },

    -- Groups
    { "<leader>b", group = "buffer", expand = function() return require("which-key.extras").expand.buf() end },
    { "<leader>c", group = "code" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "file/find" },
    { "<leader>g", group = "git" },
    { "<leader>q", group = "quit/session" },
    { "<leader>r", group = "run/tasks" },
    { "<leader>s", group = "search/replace" },
    { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
    { "<leader>w", group = "windows", proxy = "<c-w>", expand = function() return require("which-key.extras").expand.win() end },
    { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
    { "[", group = "prev" },
    { "]", group = "next" },
    { "g", group = "goto" },

    -- File / Find (FZF-Lua & Oil.nvim)
    { "<leader><leader>", function() require("fzf-lua").files() end, desc = "Find Files (FZF)" },
    { "<leader>ff", function() require("fzf-lua").files() end, desc = "Find Files (FZF)" },
    { "<leader>fg", function() require("fzf-lua").live_grep() end, desc = "Live Grep" },
    { "<leader>fb", function() require("fzf-lua").buffers() end, desc = "Buffers" },
    { "<leader>fc", function() require("snacks").dashboard.pick('files', {cwd = vim.fn.stdpath('config')}) end, desc = "Open Config" },
    
    -- Specialized Find (Restored Grep In)
    { "<leader>fi", group = "Grep In" },
    { "<leader>fid", function() require('fzf-lua').live_grep({ cwd = vim.fn.expand('%:p:h') }) end, desc = "Current Directory" },
    { "<leader>fip", function() require('fzf-lua').live_grep({ cwd = vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':h') }) end, desc = "Parent Directory" },
    
    { "<leader>fw", group = "Workspace" },
    { "<leader>fws", function() require("fzf-lua").lsp_workspace_symbols() end, desc = "Workspace Symbols" },
    { "<leader>fwd", function() require("fzf-lua").diagnostics_workspace() end, desc = "Workspace Diagnostics" },
    { "<leader>e", "<cmd>Oil --float<CR>", desc = "Oil File Explorer (Floating)" },
    { "-", function() require("oil").open() end, desc = "Oil Parent Directory" },

    -- Code / LSP
    { "gd", "<cmd>FzfLua lsp_definitions jump1=true ignore_current_line=true<cr>", desc = "Goto Definition" },
    { "gr", "<cmd>FzfLua lsp_references jump1=true ignore_current_line=true<cr>", desc = "References" },
    { "gI", "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>", desc = "Goto Implementation" },
    { "gy", "<cmd>FzfLua lsp_typedefs jump1=true ignore_current_line=true<cr>", desc = "Goto Type Definition" },
    { "K", function() vim.lsp.buf.hover() end, desc = "LSP Hover Docs" },
    { "<leader>cd", function() vim.diagnostic.open_float() end, desc = "Line Diagnostic Float" },
    { "<leader>cr", vim.lsp.buf.rename, desc = "Rename (LSP)" },
    { "<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", desc = "Code Action (LSP)" },
    { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", desc = "Switch Header/Source (C++)" },
    { "<leader>cn", function() require("neogen").generate() end, desc = "Generate Annotations (Neogen)" },
    { "<leader>ss", function() require("fzf-lua").lsp_document_symbols() end, desc = "Goto Symbol" },

    -- Search & Replace (Grug-Far & RipSubstitute)
    { "<leader>sa", "<cmd>FzfLua autocmds<cr>", desc = "Auto Commands" },
    { "<leader>sb", "<cmd>FzfLua grep_curbuf<cr>", desc = "Buffer" },
    { "<leader>sc", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
    { "<leader>sC", "<cmd>FzfLua commands<cr>", desc = "Commands" },
    { "<leader>sr", function() require("grug-far").open({ transient = true }) end, desc = "Search & Replace (Grug-Far)" },
    { "<leader>sw", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Replace Word" },
    { "<leader>fs", ":RipSubstitute<cr>", mode = { "n", "x" }, desc = "Rip Substitute (Regex)" },

    -- Git (Gitsigns)
    { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk" },
    { "<leader>gb", function() require("gitsigns").blame_line() end, desc = "Blame Line" },
    { "<leader>gB", function() require("gitsigns").blame() end, desc = "Show All Blame" },
    { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "Reset Hunk" },

    -- Diagnostics & Trouble
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0 filter.severity=vim.diagnostic.severity.ERROR<cr>", desc = "Buffer Errors" },
    { "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0 filter.severity=vim.diagnostic.severity.WARN<cr>", desc = "Buffer Warnings" },
    { "<leader>xa", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics" },
    { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
    { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP References/Definitions (Trouble)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    
    { "]e", function() goto_next_diagnostic(vim.diagnostic.severity.ERROR) end, desc = "Next Error" },
    { "[e", function() goto_prev_diagnostic(vim.diagnostic.severity.ERROR) end, desc = "Prev Error" },
    { "]w", function() goto_next_diagnostic(vim.diagnostic.severity.WARN) end, desc = "Next Warning" },
    { "[w", function() goto_prev_diagnostic(vim.diagnostic.severity.WARN) end, desc = "Prev Warning" },
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },

    -- Tasks / Run (Overseer)
    { "<leader>rs", "<cmd>OverseerRun<CR>", desc = "Run Task" },
    { "<leader>rt", "<cmd>OverseerToggle<CR>", desc = "Toggle Task List" },
    { "<leader>ri", "<cmd>OverseerInfo<CR>", desc = "Overseer Info" },
    { "<leader>rb", "<cmd>OverseerBuild<CR>", desc = "Build Task" },

    -- Sessions (Persistence.nvim)
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Session" },

    -- UI / Misc
    { "<leader>ul", "<cmd>LspRestart<cr>", desc = "Restart LSP" },
    { "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>ud", function() Snacks.dashboard.open() end, desc = "Open Dashboard" },
    { "gx", desc = "Open with system app" },
})
