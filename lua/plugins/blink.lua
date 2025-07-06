-- plugins/blink.lua ------------------------------------------------------
return {
  -- blink.cmp (replaces nvim-cmp)
  {
    "saghen/blink.cmp",
    version = '1.*',
    dependencies = { "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets" },
    opts = {
      keymap     = { preset = "default" },  -- C-y accept, C-space menu, etc.
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = false } },
      sources    = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy      = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },

  -- Snippet engine
  { "L3MON4D3/LuaSnip",             version = "1.*", build = "make install_jsregexp", opts = {} },
  { "rafamadriz/friendly-snippets", lazy = true },
}
