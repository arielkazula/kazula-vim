-- lua/core/keymaps.lua ---------------------------------------------------
-- The Central Source of Truth for all keybindings.
-- Uses `which-key.nvim` (v3+) for intuitive grouping.

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
    -- Instant Navigation (Flash)
    { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash Jump" },
    { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash Treesitter" },

    -- Window / Split Navigation (Smart Splits)
    { "<C-h>", function() require('smart-splits').move_cursor_left() end, desc = "Go to Left Split" },
    { "<C-j>", function() require('smart-splits').move_cursor_down() end, desc = "Go to Down Split" },
    { "<C-k>", function() require('smart-splits').move_cursor_up() end, desc = "Go to Up Split" },
    { "<C-l>", function() require('smart-splits').move_cursor_right() end, desc = "Go to Right Split" },

    -- Standard Mappings
    { "<leader><Bar>", ":vsplit<cr>", desc = "Split Screen Vertical" },
    { "<leader>_ ", ":split<cr>", desc = "Split Screen Horizontal" },
    { "<A-[>", ":bprevious<CR>", desc = "Previous Buffer" },
    { "<A-]>", ":bnext<CR>", desc = "Next Buffer" },
    { "<leader>cc", ":lua CopyFilePathAndLine()<CR>", desc = "Copy File Path and Line" },

    -- Group: [b]uffer
    { "<leader>b", group = "buffer", icon = { icon = "󰈙 ", color = "azure" }, expand = function() return require("which-key.extras").expand.buf() end },
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
    { "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "Pick & Close" },

    -- Group: [c]ode
    { "<leader>c", group = "code", icon = { icon = "󰅩 ", color = "yellow" } },
    { "gd", "<cmd>FzfLua lsp_definitions jump1=true<cr>", desc = "Goto Definition" },
    { "grr", "<cmd>FzfLua lsp_references include_declaration=true jump1=true<cr>", desc = "References (FZF)" },
    { "grR", function() require("core.lsp_utils").smart_references() end, desc = "Smart References (Grep + LSP)" },
    { "gri", "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>", desc = "Goto Implementation" },
    { "gy", "<cmd>FzfLua lsp_typedefs jump1=true ignore_current_line=true<cr>", desc = "Goto Type Definition" },
    { "gra", function() vim.lsp.buf.code_action() end, desc = "Code Action" },
    { "grn", vim.lsp.buf.rename, desc = "Rename (LSP)" },
    { "K", function() vim.lsp.buf.hover() end, desc = "LSP Hover Docs" },
    { "<leader>cd", function() require("neogen").generate() end, desc = "Doxygen Annotation" },
    { "<leader>cl", function() vim.diagnostic.open_float() end, desc = "Line Diagnostic Float" },
    { "<leader>cr", vim.lsp.buf.rename, desc = "Rename symbol" },
    { "<leader>ca", function() vim.lsp.buf.code_action() end, desc = "Code Actions" },
    { "<leader>co", "<cmd>AerialToggle! left<cr>", desc = "Outline (Aerial)" },
    { "<leader>cv", function() require("core.struct_layout").show_layout() end, desc = "View Detailed Struct Layout" },
    { "<leader>cA", "<cmd>ClangdAST<CR>", desc = "View Detailed AST (Layout/Offsets)" },
    { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", desc = "Switch Header/Source (C++)" },
    { "<leader>cn", function() require("neogen").generate() end, desc = "Generate Annotations" },
    { "<leader>cs", function() require("fzf-lua").lsp_document_symbols() end, desc = "Document Symbols" },
    { "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "Format Buffer" },
    
    -- Sub-Group: [c]ode [m]cmake
    { "<leader>cm", group = "cmake", icon = { icon = "󰔚 ", color = "blue" } },
    { "<leader>cmg", "<cmd>CMakeGenerate<cr>", desc = "Generate" },
    { "<leader>cmb", "<cmd>CMakeBuild<cr>", desc = "Build" },
    { "<leader>cmr", "<cmd>CMakeRun<cr>", desc = "Run" },
    { "<leader>cmc", "<cmd>CMakeConfigure<cr>", desc = "Configure" },
    { "<leader>cmt", "<cmd>CMakeSelectBuildTarget<cr>", desc = "Select Target" },
    { "<leader>cmv", "<cmd>CMakeSelectBuildType<cr>", desc = "Select Variant" },
    { "<leader>cms", "<cmd>CMakeStop<cr>", desc = "Stop" },

    -- Sub-Group: [c]ode [r]refactor
    { "<leader>cx", group = "refactor", icon = { icon = "󰪹 ", color = "orange" } },
    { "<leader>cxe", function() require('refactoring').refactor('Extract Function') end, mode = { "v" }, desc = "Extract Function" },
    { "<leader>cxf", function() require('refactoring').refactor('Extract Function To File') end, mode = { "v" }, desc = "Extract To File" },
    { "<leader>cxv", function() require('refactoring').refactor('Extract Variable') end, mode = { "v" }, desc = "Extract Variable" },
    { "<leader>cxi", function() require('refactoring').refactor('Inline Variable') end, mode = { "n", "v" }, desc = "Inline Variable" },

    -- Group: [f]ile
    { "<leader>f", group = "file", icon = { icon = "󰈞 ", color = "blue" } },
    { "<leader>ff", function() require("fzf-lua").files() end, desc = "Find Files" },
    { "<leader>fd", function() require("core.fzf_utils").pick_dir_then_search("files") end, desc = "Find in Folder" },
    { "<leader>fb", function() require("core.fzf_utils").file_driller() end, desc = "File Driller (Hierarchy)" },
    { "<leader>fB", function() require("fzf-lua").buffers() end, desc = "Find Buffers" },
    { "<leader>fr", function() require("fzf-lua").oldfiles() end, desc = "Recent Files" },
    { "<leader>fc", function() require("snacks").dashboard.pick('files', {cwd = vim.fn.stdpath('config')}) end, desc = "Config Files" },
    { "<leader>fe", "<cmd>Oil --float<CR>", desc = "File Explorer (Oil)" },
    { "-", function() require("oil").open() end, desc = "Open Parent Directory" },

    -- Group: [g]it
    { "<leader>g", group = "git", icon = { icon = "󰊢 ", color = "orange" } },
    { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk" },
    { "<leader>gb", function() require("gitsigns").blame_line() end, desc = "Blame Line" },
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },

    -- Sub-Group: [g]it [x] conflicts
    { "<leader>gx", group = "conflicts", icon = { icon = "󰆚 ", color = "red" } },
    { "<leader>gxo", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours" },
    { "<leader>gxt", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs" },
    { "<leader>gxb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both" },
    { "<leader>gx0", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None" },
    { "<leader>gx]", "<cmd>GitConflictNextConflict<cr>", desc = "Next Conflict" },
    { "<leader>gx[", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev Conflict" },

    -- Group: [h]arpoon
    { "<leader>h", group = "harpoon", icon = { icon = "󰛢 ", color = "red" } },
    { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Add File" },
    { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Menu" },

    -- Group: [q]uit/session
    { "<leader>q", group = "session", icon = { icon = "󰗼 ", color = "purple" } },
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last" },

    -- Group: [r]un (Overseer)
    { "<leader>r", group = "run/tasks", icon = { icon = "󰐊 ", color = "green" } },
    { "<leader>rs", "<cmd>OverseerRun<CR>", desc = "Run Task" },
    { "<leader>rt", "<cmd>OverseerToggle<CR>", desc = "Toggle Task List" },

    -- Direct Task Access (NEW)
    { "<leader>rc", function() require("overseer").run_task({ name = "C++: Generate compile_commands" }) end, desc = "Generate Compile Commands" },
    { "<leader>rb", function() require("overseer").run_task({ name = "Project: Rebuild (gcc Debug)" }) end, desc = "Rebuild (gcc Debug)" },

    -- Group: [s]earch
    { "<leader>s", group = "search", icon = { icon = "󰍉 ", color = "cyan" } },
    { "<leader>sg", function() require("fzf-lua").live_grep() end, desc = "Live Grep" },
    { "<leader>sd", function() require("core.fzf_utils").pick_dir_then_search("live_grep") end, desc = "Grep in Folder" },
    { "<leader>sw", function() require("fzf-lua").grep_cword() end, desc = "Search Word" },
    { "<leader>sq", function() require("core.fzf_quick_sheet").show_quick_sheet() end, desc = "Search Quick Sheet" },
    { "<leader>sr", function() require("grug-far").open({ transient = true }) end, desc = "Search & Replace" },
    { "<leader>sf", ":RipSubstitute<cr>", desc = "Rip Substitute" },
    { "<leader>st", "<cmd>TodoFzfLua keywords=TODO<cr>", desc = "Search Project TODOs" },

    -- Group: [u]i
    { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
    { "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>ud", function() Snacks.dashboard.open() end, desc = "Dashboard" },
    { "<leader>uf", "za", desc = "Toggle Fold" },
    { "<leader>ul", "<cmd>LspRestart<cr>", desc = "Restart LSP" },

    -- Group: [x] diagnostics
    { "<leader>x", group = "diagnostics", icon = { icon = "󱖫 ", color = "green" } },
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics" },
    { "<leader>xt", "<cmd>TodoTrouble filter = {tag = {TODO}}<cr>", desc = "Project TODOs (Trouble)" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },

    -- Navigation
    { "[e", function() goto_prev_diagnostic(vim.diagnostic.severity.ERROR) end, desc = "Prev Error" },
    { "]e", function() goto_next_diagnostic(vim.diagnostic.severity.ERROR) end, desc = "Next Error" },
    { "[w", function() goto_prev_diagnostic(vim.diagnostic.severity.WARN) end, desc = "Prev Warning" },
    { "]w", function() goto_next_diagnostic(vim.diagnostic.severity.WARN) end, desc = "Next Warning" },
    { "[q", "<cmd>cprev<cr>", desc = "Prev Quickfix" },
    { "]q", "<cmd>cnext<cr>", desc = "Next Quickfix" },
    { "[t", function() require("todo-comments").jump_prev({ keywords = { "TODO" } }) end, desc = "Prev TODO" },
    { "]t", function() require("todo-comments").jump_next({ keywords = { "TODO" } }) end, desc = "Next TODO" },
    
    { "gx", desc = "Open with system app" },
})
