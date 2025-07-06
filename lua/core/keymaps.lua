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

-- Misc -------------------------------------------------------------------
map({ "n", "v" }, "<leader>w", "<cmd>w<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))
map("n", "<leader>q", "<cmd>qa<CR>", vim.tbl_extend("force", opts, { desc = "Quit all" }))



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
    -- LSP Keymaps for navigation
    {
        "gd",
        "<cmd>lua vim.lsp.buf.definition()<CR>",
        desc = "Go to Definition",
    },
    {
        "gr",
        "<cmd>lua vim.lsp.buf.references()<CR>",
        desc = "Show References",
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
        "]e",
        '<cmd>lua require("todo-comments").jump_next({ keywords = { "ERROR", "WARNING" } })<CR>',
        desc = "Next Error/Warning TODO",
    },
    {
        "[e",
        '<cmd>lua require("todo-comments").jump_prev({ keywords = { "ERROR", "WARNING" } })<CR>',
        desc = "Previous Error/Warning TODO",
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
})
