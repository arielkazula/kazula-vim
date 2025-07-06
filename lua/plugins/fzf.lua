-- plugins/fzf.lua --------------------------------------------------------
return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {}, -- defaults are great; customise if desired
  },
  -- (optional) grab fzf binary if not already in the container
  {
    "junegunn/fzf",
    run = function()
      vim.fn["fzf#install"]()
    end,
  },
}
