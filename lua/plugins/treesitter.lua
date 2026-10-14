-- lua/plugins/treesitter.lua ---------------------------------------------
-- Tree-sitter parsers + highlighting (nvim-treesitter `main` branch API).
-- Parser installation requires the `tree-sitter` CLI and a C compiler.

local parsers = {
    "c", "cpp", "lua", "python", "bash", "cmake", "json",
    "markdown", "markdown_inline", "vim", "vimdoc", "query",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install(parsers)

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("kazula_treesitter", { clear = true }),
                callback = function(args)
                    -- Start highlighting only if a parser exists for this filetype.
                    if pcall(vim.treesitter.start, args.buf) then
                        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
