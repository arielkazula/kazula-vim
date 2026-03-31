-- core/keymaps.lua -------------------------------------------------------
local map, opts = vim.keymap.set, { noremap = true, silent = true }

-- File search & browsing -------------------------------------------------
map("n", "<leader><leader>", function() require("fzf-lua").files() end,
    vim.tbl_extend("force", opts, { desc = "Find files (fzf)" }))
map("n", "<leader>fg", function() require("fzf-lua").live_grep() end,
    vim.tbl_extend("force", opts, { desc = "Live grep (fzf)" }))
map("n", "<leader>fb", function() require("fzf-lua").buffers() end,
    vim.tbl_extend("force", opts, { desc = "Buffers (fzf)" }))

map("n", "<leader>e", "<cmd>Oil<CR>",
    vim.tbl_extend("force", opts, { desc = "Oil file explorer" }))
map("n", "-", function() require("oil").open() end,
    vim.tbl_extend("force", opts, { desc = "Oil parent dir" }))

-- LSP helper -------------------------------------------------------------
map("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>",
    vim.tbl_extend("force", opts, { desc = "Switch header/source" }))




-- keymaps.lua
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Function to copy the current file path and line number
function CopyFilePathAndLine()
    local filepath = vim.fn.expand("%")
    local line_number = vim.fn.line(".")
    local result = filepath .. ":" .. line_number

    -- Copy to system clipboard
    vim.fn.setreg("+", result)

    -- Notify the user
    print("Copied: " .. result)
end

-- Function to jump to the next error using Trouble.nvim if open, else LSP
function goto_next_warning()
    vim.diagnostic.goto_next({
        severity = vim.diagnostic.severity.WARN,
        wrap = true, -- wrap around file
    })
end

-- Function to jump to the previous error
function goto_prev_warning()
    vim.diagnostic.goto_prev({
        severity = vim.diagnostic.severity.WARN,
        wrap = true,
    })
end

-- Function to jump to the next error using Trouble.nvim if open, else LSP
function goto_next_error()
    vim.diagnostic.goto_next({
        severity = vim.diagnostic.severity.ERROR, -- restrict to errors only
        wrap = true,                              -- wrap around file
    })
end

-- Function to jump to the previous error
function goto_prev_error()
    vim.diagnostic.goto_prev({
        severity = vim.diagnostic.severity.ERROR,
        wrap = true,
    })
end

-- Keymaps
local wk = require("which-key")

-- Register mappings with `which-key.add`
wk.add({

    { "<leader>e",  "<cmd>Oil --float <CR>" },
    -- Group for Grep In
    { "<leader>fi", group = "Grep In" },
    {
        "<leader>fid",
        "<cmd>lua require('fzf-lua').live_grep({ cwd = vim.fn.expand('%:p:h') })<CR>",
        desc = "Current Directory",
    },
    {
        "<leader>fip",
        "<cmd>lua require('fzf-lua').live_grep({ cwd = vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':h') })<CR>",
        desc = "Parent Directory",
    },
    -- Generate Doxygen comments with Neogen
    {
        "<leader>ng",
        ':lua require("neogen").generate()<CR>',
        desc = "Generate Doxygen Comments",
    },
    -- Fast buffer navigation
    {
        "<A-[>",
        ":bprevious<CR>",
        desc = "Previous Buffer",
    },
    {
        "<A-]>",
        ":bnext<CR>",
        desc = "Next Buffer",
    },
    -- Todo-comments navigation
    {
        "]t",
        '<cmd>lua require("todo-comments").jump_next()<CR>',
        desc = "Next TODO",
    },
    {
        "[t",
        '<cmd>lua require("todo-comments").jump_prev()<CR>',
        desc = "Previous TODO",
    },
    {
        "]w",
        ':lua goto_next_warning()<CR>',
        desc = "Next WARNING",
    },
    {
        "[w",
        ':lua goto_prev_warning()<CR>',
        desc = "Previous WARNING",
    },
    {
        "]e",
        ':lua goto_next_error()<CR>',
        desc = "Next Error",
    },
    {
        "[e",
        ':lua goto_prev_error()<CR>',
        desc = "Previous Error",
    },
    -- Copy file path and line number
    {
        "<leader>cc",
        ":lua CopyFilePathAndLine()<CR>",
        desc = "Copy File Path and Line",
    }, -- Subgroup for Find -> Document
    -- Subgroup for Find -> Workspace
    { "<leader>fw", group = "Workspace" },
    {
        "<leader>fws",
        function()
            require("fzf-lua").lsp_workspace_symbols()
        end,
        desc = "Workspace Symbols (FZF)",
    },
    {
        "<leader>fwd",
        function()
            require("fzf-lua").diagnostics_workspace()
        end,
        desc = "Workspace Diagnostics (FZF)",
    },
    {
        "<leader>ss",
        function()
            require("fzf-lua").lsp_document_symbols({
                regex_filter = symbols_filter,
            })
        end,
        desc = "Goto Symbol",
    },

    { "<leader>sa", "<cmd>FzfLua autocmds<cr>", desc = "Auto Commands" },
    { "<leader>sb", "<cmd>FzfLua grep_curbuf<cr>", desc = "Buffer" },
    { "<leader>sg", "<cmd>FzfLua grep_visual<cr>", desc = "Grep" },
    { "<leader>sc", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
    { "<leader>sC", "<cmd>FzfLua commands<cr>", desc = "Commands" },
    { "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document Diagnostics" },
    { "<leader>qq", "<cmd>FzfLua quickfix<cr>", desc = "Quickfix" },
    { "<leader>ql", "<cmd>FzfLua quickfix_stack<cr>", desc = "Quickfix List" },
    { "<leader>qc", "<cmd>:cclose<cr>", desc = "Quickfix Close" },

    { "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
    { "<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", desc = "Source Action" },

    { "gd", "<cmd>FzfLua lsp_definitions     jump1=true ignore_current_line=true<cr>", desc = "Goto Definition" },
    { "gr", "<cmd>FzfLua lsp_references      jump1=true ignore_current_line=true<cr>", desc = "References", nowait = true },
    { "gI", "<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>", desc = "Goto Implementation" },
    { "gy", "<cmd>FzfLua lsp_typedefs        jump1=true ignore_current_line=true<cr>", desc = "Goto T[y]pe Definition" },
    { "<leader>fc", ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})<cr>", desc = "Open Configuration Files" },
    { "<leader><Bar>", ":vsplit<cr>", desc = "Split Screen" },
    { "<leader>xx", "<cmd>Trouble diagnostics toggle win.position=right filter.buf=0 filter.severity=vim.diagnostic.severity.ERROR <cr>", desc = "Errors" },
    { "<leader>xw", "<cmd>Trouble diagnostics toggle win.position=right filter.buf=0 filter.severity=vim.diagnostic.severity.WARN <cr>", desc = "Warnings" },
    { "<leader>xa", "<cmd>Trouble diagnostics toggle win.position=right filter.buf=0  <cr>", desc = "Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle win.position=right <cr>", desc = "Workspace Diagnostics (Trouble)" },
    { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
    { "<leader>gb", "<cmd>Gitsigns blame_line<cr>", desc = "Blame Line" },
    { "<leader>gB", "<cmd>Gitsigns blame<cr>", desc = "Show all Blame" },
    { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset Hunk" },
    { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    { "<leader>fs", ":RipSubstitute<cr>", mode = { "n", "x" }, desc = " rip substitute" },
    { "<Leader>rs", "<cmd>Greyjoy<CR>", desc = "[r]un [S]cript " },
    { "<Leader>re", "<cmd>Greyedit<CR>", desc = "[e]edit before run  [S]cript " },

})



require("fzf-lua").setup({
    keymap = {
        fzf = {
            ["ctrl-q"] = "select-all+accept",
        },
    },
})
