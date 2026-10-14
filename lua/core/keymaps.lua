-- lua/core/keymaps.lua ---------------------------------------------------
-- Single source of truth for all keybindings.
-- Uses which-key (v3+) for grouping and discoverability.
--
-- Layout:
--   Bare keys      — Flash, splits navigation, buffer cycling
--   g* motions     — Standard Neovim LSP go-to motions (gd, grr, grR, gri, gy, K)
--   <leader>b      — Buffer management
--   <leader>c      — Code / LSP actions
--     <leader>cm   — CMake build system
--     <leader>cx   — Refactoring
--   <leader>f      — File navigation
--   <leader>g      — Git (neogit, gitsigns, diffview, gitlinker)
--     <leader>gx   — Merge conflict resolution
--     <leader>go   — GitHub (Octo: PRs, reviews)
--   <leader>h      — Harpoon marks
--   <leader>q      — Session management
--   <leader>r      — Run / task runner (Overseer)
--   <leader>s      — Search (fzf-lua + grep)
--   <leader>u      — UI toggles
--   <leader>x      — Diagnostics (Trouble)
--   [ / ]          — Next/prev navigation (errors, warnings, quickfix, TODOs,
--                    git hunks, merge conflicts)
--   Oil buffer     — <BS> up a folder, gy copy full path, <C-v>/<C-x> open in split

local wk = require("which-key")

-- ── Helper Functions ─────────────────────────────────────────────────────
vim.diagnostic.config({ jump = { float = true } })

-- Copy "filepath:line" to the system clipboard (useful for issue references).
_G.CopyFilePathAndLine = function()
    local result = vim.fn.expand("%") .. ":" .. vim.fn.line(".")
    vim.fn.setreg("+", result)
    vim.notify("Copied: " .. result, vim.log.levels.INFO)
end

local function goto_next_diag(severity)
    vim.diagnostic.jump({ severity = severity, count = 1 })
end
local function goto_prev_diag(severity)
    vim.diagnostic.jump({ severity = severity, count = -1 })
end

-- ── Mappings ─────────────────────────────────────────────────────────────

wk.add({

    -- ── Instant navigation (Flash) ───────────────────────────────────────
    {
        "s",
        function() require("flash").jump() end,
        mode = { "n", "x", "o" },
        desc = "Flash: jump"
    },
    {
        "S",
        function() require("flash").treesitter() end,
        mode = { "n", "x", "o" },
        desc = "Flash: treesitter node"
    },

    -- ── Window / split navigation (Smart Splits) ─────────────────────────
    { "<C-h>",      function() require("smart-splits").move_cursor_left() end,                 desc = "Focus left split" },
    { "<C-j>",      function() require("smart-splits").move_cursor_down() end,                 desc = "Focus split below" },
    { "<C-k>",      function() require("smart-splits").move_cursor_up() end,                   desc = "Focus split above" },
    { "<C-l>",      function() require("smart-splits").move_cursor_right() end,                desc = "Focus right split" },

    -- ── Window / buffer basics ────────────────────────────────────────────
    { "<leader>|",  ":vsplit<cr>",                                                             desc = "Split vertical" },
    { "<leader>_",  ":split<cr>",                                                              desc = "Split horizontal" },
    { "<A-[>",      ":bprevious<CR>",                                                          desc = "Previous buffer" },
    { "<A-]>",      ":bnext<CR>",                                                              desc = "Next buffer" },
    { "<leader>cc", ":lua CopyFilePathAndLine()<CR>",                                          desc = "Copy file path + line" },

    -- ── File explorer (Oil) ───────────────────────────────────────────────
    { "-",          function() require("oil").open() end,                                      desc = "Oil: open parent dir" },

    -- ── g* LSP motions (standard Neovim / muscle-memory friendly) ────────
    -- These intentionally overlap nothing in <leader>c; they are the fast
    -- hand-on-the-keyboard versions of the same actions.
    { "gd",         "<cmd>FzfLua lsp_definitions  jump1=true<cr>",                             desc = "LSP: go to definition" },
    { "grr",        "<cmd>FzfLua lsp_references   include_declaration=true jump1=true<cr>",    desc = "LSP: references (FZF)" },
    { "grR",        function() require("core.lsp_utils").smart_references() end,               desc = "LSP: smart references (grep + inject)" },
    { "gri",        "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>", desc = "LSP: go to implementation" },
    { "gy",         "<cmd>FzfLua lsp_typedefs      jump1=true ignore_current_line=true<cr>",   desc = "LSP: go to type definition" },

    { "K",          function() vim.lsp.buf.hover() end,                                        desc = "LSP: hover docs" },
    { "gx",         desc = "Open with system app" },

    -- ── Copilot (insert mode) — <Tab> belongs to blink.cmp ───────────────
    -- <M-Tab> may be swallowed by the desktop (window switcher); <M-l> is the fallback.
    { "<M-Tab>", 'copilot#Accept("")', mode = "i", expr = true, replace_keycodes = false, desc = "Copilot: accept" },
    { "<M-l>",   'copilot#Accept("")', mode = "i", expr = true, replace_keycodes = false, desc = "Copilot: accept (fallback)" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [b]uffer ──────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    {
        "<leader>b",
        group = "buffer",
        icon = { icon = "󰈙 ", color = "azure" },
        expand = function() return require("which-key.extras").expand.buf() end
    },
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    { "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "Pick buffer to close" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [c]ode ────────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>c", group = "code", icon = { icon = "󰅩 ", color = "yellow" } },

    -- Diagnostics & docs
    { "<leader>ca", function() vim.lsp.buf.code_action() end, desc = "Code action" },
    { "<leader>cr", vim.lsp.buf.rename, desc = "Rename symbol" },
    { "<leader>cl", function() vim.diagnostic.open_float() end, desc = "Line diagnostic float" },
    { "<leader>cn", function() require("neogen").generate() end, desc = "Generate doc annotation" },

    -- Navigation & views
    { "<leader>co", "<cmd>AerialToggle! left<cr>", desc = "Toggle symbol outline (Aerial)" },
    { "<leader>cA", "<cmd>ClangdAST<CR>", desc = "View AST (clangd)" },
    { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", desc = "Switch header / source" },
    { "<leader>cs", function() require("fzf-lua").lsp_document_symbols() end, desc = "Document symbols" },

    -- Formatting (via conform.nvim; falls back to LSP for unlisted filetypes)
    {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer / selection"
    },
    {
        "<leader>cg",
        function() require("overseer").run_task({ name = "Git: Clang-Format (Changed Lines)" }) end,
        desc = "Format changed lines (git + clang-format)"
    },

    -- ── [c]ode > [m]ake (CMake) ───────────────────────────────────────────
    { "<leader>cm", group = "cmake", icon = { icon = "󰔚 ", color = "blue" } },
    { "<leader>cmg", "<cmd>CMakeGenerate<cr>", desc = "Generate" },
    { "<leader>cmb", "<cmd>CMakeBuild<cr>", desc = "Build" },
    { "<leader>cmr", "<cmd>CMakeRun<cr>", desc = "Run" },
    { "<leader>cmt", "<cmd>CMakeSelectBuildTarget<cr>", desc = "Select target" },
    { "<leader>cmv", "<cmd>CMakeSelectBuildType<cr>", desc = "Select build type" },
    { "<leader>cms", "<cmd>CMakeStop<cr>", desc = "Stop" },

    -- ── [c]ode > [x] refactor ─────────────────────────────────────────────
    { "<leader>cx", group = "refactor", icon = { icon = "󰪹 ", color = "orange" } },
    {
        "<leader>cxe",
        function() require("refactoring").refactor("Extract Function") end,
        mode = { "v" },
        desc = "Extract function"
    },
    {
        "<leader>cxf",
        function() require("refactoring").refactor("Extract Function To File") end,
        mode = { "v" },
        desc = "Extract function to file"
    },
    {
        "<leader>cxv",
        function() require("refactoring").refactor("Extract Variable") end,
        mode = { "v" },
        desc = "Extract variable"
    },
    {
        "<leader>cxi",
        function() require("refactoring").refactor("Inline Variable") end,
        mode = { "n", "v" },
        desc = "Inline variable"
    },

    -- ────────────────────────────────────────────────────────────────────────
    -- [f]ile ────────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>f", group = "file", icon = { icon = "󰈞 ", color = "blue" } },
    { "<leader>ff", function() require("fzf-lua").files() end, desc = "Find files" },
    { "<leader>fd", function() require("core.fzf_utils").pick_dir_then_search("files") end, desc = "Find files in folder" },
    { "<leader>fb", function() require("fzf-lua").buffers() end, desc = "Open buffers" },
    { "<leader>fr", function() require("fzf-lua").oldfiles() end, desc = "Recent files" },
    {
        "<leader>fc",
        function() require("snacks").dashboard.pick("files", { cwd = vim.fn.stdpath("config") }) end,
        desc = "Config files"
    },
    { "<leader>fe", "<cmd>Oil --float<CR>", desc = "File explorer (Oil float)" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [g]it ─────────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>g", group = "git", icon = { icon = "󰊢 ", color = "orange" } },
    -- Overview & diffs
    { "<leader>gs", "<cmd>Neogit<cr>", desc = "Neogit status" },
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: all changes" },
    { "<leader>gS", "<cmd>DiffviewOpen --cached<cr>", desc = "Diffview: staged changes" },
    { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
    -- Hunks & blame (gitsigns)
    {
        "<leader>ga",
        function() require("gitsigns").stage_hunk() end,
        desc = "Stage hunk"
    },
    {
        "<leader>ga",
        function() require("gitsigns").stage_hunk({ vim.fn.line("v"), vim.fn.line(".") }) end,
        mode = "v",
        desc = "Stage selected lines"
    },
    { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview hunk" },
    { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "Revert hunk" },
    {
        "<leader>gr",
        function() require("gitsigns").reset_hunk({ vim.fn.line("v"), vim.fn.line(".") }) end,
        mode = "v",
        desc = "Revert selected lines"
    },
    { "<leader>gR", function() require("gitsigns").reset_buffer() end, desc = "Revert buffer" },
    { "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame line (full)" },
    { "<leader>gB", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle inline blame" },
    -- Permalinks (gitlinker)
    { "<leader>gy", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Copy permalink" },
    { "<leader>gY", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open permalink in browser" },

    -- ── [g]it > [o]cto (GitHub) ───────────────────────────────────────────
    { "<leader>go", group = "github (octo)", icon = { icon = " ", color = "purple" } },
    { "<leader>gop", "<cmd>Octo pr list<cr>", desc = "PR list" },
    { "<leader>gor", "<cmd>Octo review<cr>", desc = "Start / resume review" },

    -- ── [g]it > [x] conflicts ─────────────────────────────────────────────
    { "<leader>gx", group = "conflicts", icon = { icon = "󰆚 ", color = "red" } },
    { "<leader>gxo", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose ours" },
    { "<leader>gxt", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose theirs" },
    { "<leader>gxb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose both" },
    { "<leader>gx0", "<cmd>GitConflictChooseNone<cr>", desc = "Choose none" },
    { "<leader>gx]", "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
    { "<leader>gx[", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev conflict" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [h]arpoon ─────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>h", group = "harpoon", icon = { icon = "󰛢 ", color = "red" } },
    { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Add file to harpoon" },
    {
        "<leader>hh",
        function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,
        desc = "Harpoon menu"
    },

    -- ────────────────────────────────────────────────────────────────────────
    -- [q]uit / session ──────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>q", group = "session", icon = { icon = "󰗼 ", color = "purple" } },
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [r]un / tasks (Overseer) ──────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>r", group = "run/tasks", icon = { icon = "󰐊 ", color = "green" } },
    { "<leader>rs", "<cmd>OverseerRun<CR>", desc = "Run task" },
    { "<leader>rt", "<cmd>OverseerToggle<CR>", desc = "Toggle task list" },
    {
        "<leader>rc",
        function() require("overseer").run_task({ name = "C++: Generate compile_commands" }) end,
        desc = "Generate compile_commands.json"
    },
    {
        "<leader>rb",
        function() require("overseer").run_task({ name = "Project: Rebuild (gcc Debug)" }) end,
        desc = "Rebuild project (gcc debug)"
    },

    -- ────────────────────────────────────────────────────────────────────────
    -- [s]earch ──────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>s", group = "search", icon = { icon = "󰍉 ", color = "cyan" } },
    { "<leader>sg", function() require("fzf-lua").live_grep() end, desc = "Live grep" },
    { "<leader>sd", function() require("core.fzf_utils").pick_dir_then_search("live_grep") end, desc = "Grep in folder" },
    { "<leader>sw", function() require("fzf-lua").grep_cword() end, desc = "Search word under cursor" },
    { "<leader>sS", function() require("fzf-lua").lsp_live_workspace_symbols() end, desc = "Workspace symbols (LSP)" },
    { "<leader>sq", function() require("core.fzf_quick_sheet").show_quick_sheet() end, desc = "Quick search sheet" },
    { "<leader>sr", function() require("grug-far").open({ transient = true }) end, desc = "Search & replace (grug-far)" },
    { "<leader>sf", ":RipSubstitute<cr>", mode = { "n", "v" }, desc = "Rip substitute (buffer)" },
    { "<leader>st", "<cmd>TodoFzfLua<cr>", desc = "Search all project tags (TODO…)" },
    { "<leader>sT", "<cmd>TodoFzfLua cwd=%:p:h<cr>", desc = "Search tags in current folder" },
    { "<leader>sb", "<cmd>TodoFzfLua filter=buf=0<cr>", desc = "Search tags in current buffer" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [u]i ──────────────────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
    { "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification history" },
    { "<leader>ud", function() Snacks.dashboard.open() end, desc = "Open dashboard" },
    { "<leader>uf", "za", desc = "Toggle fold" },
    { "<leader>ul", "<cmd>LspRestart<cr>", desc = "Restart LSP" },
    { "<leader>uz", "<cmd>ZenMode<cr>", desc = "ZenMode" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [x] diagnostics ───────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "<leader>x", group = "diagnostics", icon = { icon = "󱖫 ", color = "green" } },
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace diagnostics" },
    { "<leader>xt", "<cmd>TodoTrouble filter = {tag = {TODO}}<cr>", desc = "Project TODOs (Trouble)" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },

    -- ────────────────────────────────────────────────────────────────────────
    -- [ / ] navigation ──────────────────────────────────────────────────────
    -- ────────────────────────────────────────────────────────────────────────
    { "[e", function() goto_prev_diag(vim.diagnostic.severity.ERROR) end, desc = "Prev error" },
    { "]e", function() goto_next_diag(vim.diagnostic.severity.ERROR) end, desc = "Next error" },
    { "[w", function() goto_prev_diag(vim.diagnostic.severity.WARN) end, desc = "Prev warning" },
    { "]w", function() goto_next_diag(vim.diagnostic.severity.WARN) end, desc = "Next warning" },
    { "[q", "<cmd>cprev<cr>", desc = "Prev quickfix item" },
    { "]q", "<cmd>cnext<cr>", desc = "Next quickfix item" },
    { "[t", function() require("todo-comments").jump_prev({ keywords = { "TODO" } }) end, desc = "Prev TODO" },
    { "]t", function() require("todo-comments").jump_next({ keywords = { "TODO" } }) end, desc = "Next TODO" },
    { "[h", function() require("gitsigns").nav_hunk("prev") end, desc = "Prev git hunk" },
    { "]h", function() require("gitsigns").nav_hunk("next") end, desc = "Next git hunk" },
    { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev merge conflict" },
    { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next merge conflict" },
})

-- ── Buffer-local: Oil file explorer ──────────────────────────────────────
-- Oil's own defaults (-, _, <CR>, g., g?, …) still apply; these extend them.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("kazula_oil_keymaps", { clear = true }),
    pattern = "oil",
    callback = function(args)
        wk.add({
            buffer = args.buf,
            { "<BS>", function() require("oil.actions").parent.callback() end, desc = "Oil: up a folder" },
            {
                "<C-v>",
                function() require("oil").select({ vertical = true }) end,
                desc = "Oil: open in vertical split",
            },
            {
                "<C-x>",
                function() require("oil").select({ horizontal = true }) end,
                desc = "Oil: open in horizontal split",
            },
            {
                "gy",
                function()
                    local oil = require("oil")
                    local entry, dir = oil.get_cursor_entry(), oil.get_current_dir()
                    if entry and dir then
                        local path = dir .. entry.name
                        vim.fn.setreg("+", path)
                        vim.notify("Copied: " .. path, vim.log.levels.INFO)
                    end
                end,
                desc = "Oil: copy full path",
            },
        })
    end,
})
