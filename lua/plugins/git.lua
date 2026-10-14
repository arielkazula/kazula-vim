-- lua/plugins/git.lua ----------------------------------------------------
-- All Git / GitHub tooling. Keymaps live in core/keymaps.lua under
-- <leader>g; plugins lazy-load on their commands.

return {
    -- 1. In-buffer signs, hunk actions and inline blame
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "│" },
                change       = { text = "│" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
            },
            current_line_blame = true, -- toggle with <leader>gB
            current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
        },
    },

    -- 2. Repository porcelain (status / commit / push) in a split
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "ibhagwan/fzf-lua",
        },
        opts = {
            kind = "split",
            integrations = {
                diffview  = true,
                fzf_lua   = true,
                telescope = false,
                snacks    = false,
            },
        },
    },

    -- 3. Tabpage diff and history viewer
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        opts = { enhanced_diff_hl = true },
    },

    -- 4. Merge conflict resolver (mappings in <leader>gx and [x / ]x)
    {
        "akinsho/git-conflict.nvim",
        version = "*",
        event = "BufReadPre",
        opts = {
            default_mappings = false,
            disable_diagnostics = true,
        },
    },

    -- 5. GitHub issues and PR reviews (requires `gh` CLI, authenticated)
    {
        "pwntester/octo.nvim",
        cmd = "Octo",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "ibhagwan/fzf-lua",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            picker = "fzf-lua",
            enable_builtin = true,
        },
    },

    -- 6. Permalinks to the remote host (GitHub, GitLab, …)
    {
        "linrongbin16/gitlinker.nvim",
        cmd = "GitLink",
        opts = {},
    },
}
