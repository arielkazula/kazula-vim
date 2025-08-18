-- plugins/lsp.lua --------------------------------------------------------
return {
    { "williamboman/mason.nvim",   config = true },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = "williamboman/mason.nvim",
        opts = { ensure_installed = { "clangd" } },
    },


    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "bash",
                "json",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "regex",
                "vim",
                "cpp", -- C++ parser
                "c",   -- C parser
            },
        },
    },
    { "nvim-treesitter/playground" },

    -- Documentation generator (Doxygen-style via Neogen)
    {
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("neogen").setup({
                enabled = true,
                languages = {
                    cpp = {
                        template = {
                            annotation_convention = "custom",
                            custom = {
                                { nil,                "/**",             { no_results = true, type = { "func", "file" } } },
                                { nil,                " * @file",        { no_results = true, type = { "file" } } },
                                { nil,                " * $1",           { no_results = true, type = { "func", "file" } } },
                                { nil,                " */",             { no_results = true, type = { "func", "file" } } },
                                { nil,                "" },
                                { nil,                "/**",             { type = { "func" } } },
                                { nil,                " * $1",           { type = { "func" } } },
                                { nil,                " *" },
                                { "tparam",           " * @tparam %s $1" },
                                { "parameters",       " * @param %s $1" },
                                { "return_statement", " * @return $1" },
                                { nil,                " */" },
                            },
                        },
                    },
                },
            })
        end,
    },



    { -- nvim-lspconfig + clangd-extensions
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "p00f/clangd_extensions.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            local caps = require("blink.cmp").get_lsp_capabilities()
            local util = require("lspconfig.util")

            require("clangd_extensions").setup({
                server = {
                    capabilities = caps,
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--completion-style=detailed",
                        "--header-insertion=iwyu",
                        "--function-arg-placeholders",
                        "--fallback-style=llvm",
                        "--offset-encoding=utf-16",
                    },
                    root_dir = util.root_pattern(
                        "compile_commands.json", "compile_flags.txt",
                        "Makefile", "meson.build", "build.ninja"
                    ) or util.find_git_ancestor,
                },
                extensions = {
                    autoSetHints = true,
                    inlay_hints  = { inline = false },
                },
            })
        end,
    },
    {
        "stevearc/conform.nvim",
    },
    {
        "folke/trouble.nvim",
        cmd = { "Trouble" },
        opts = {
            modes = {
                lsp = {
                    win = { position = "right" },
                },
            },
        },
    },
    {
        "folke/todo-comments.nvim",
        cmd = { "TodoTrouble" },
        opts = {},
    },
    -- Neogen for generating Doxygen comments
    {
        "danymat/neogen",
        keys = {
            {
                "<leader>cn",
                function()
                    require("neogen").generate()
                end,
                desc = "Generate Annotations (Neogen)",
            },
        },
    },
}
