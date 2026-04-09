-- lua/plugins/completion.lua ---------------------------------------------
-- This file handles the autocompletion engine and snippet support.
-- Using blink.cmp, a high-performance completion engine written in Rust.

return {
  {
    "saghen/blink.cmp",
    -- version = '*', -- Using main branch for latest fixes
    branch = "main",
    build = "cargo build --release", -- Ensure binary is built correctly
    dependencies = { 
      "rafamadriz/friendly-snippets",
      -- Add lazydev for better Neovim Lua API completion
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    opts = {
      keymap = { preset = "default" },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        ghost_text = { enabled = true },
      },
      sources = {
        -- Added 'lazydev' to the default list of providers
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- show at the top
          },
        },
      },
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },

  -- Collection of common snippets for all languages
  { "rafamadriz/friendly-snippets", lazy = true },
}
