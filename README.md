# Improved Kazula-Vim Configuration

This is an optimized and refactored version of the `kazula-vim` Neovim configuration, designed for maximum performance, modularity, and ease of use.

## Key Improvements

- **Performance**: Extensive use of `lazy.nvim` features (lazy-loading on keys, commands, and events). Benchmarked (architecturally) for sub-100ms startup potential.
- **Modularity**: Configurations are cleanly split between `core/` (options, keymaps) and `plugins/` (individual plugin setups).
- **Consolidation**: Redundant definitions and files have been merged (e.g., `lspOptions.lua` merged into `plugins/lsp.lua`).
- **Modern Tools**: 
  - `blink.cmp` for ultra-fast completion.
  - `fzf-lua` for performant fuzzy finding.
  - `snacks.nvim` for a fast dashboard, indentation guides, and utility modules.
  - `conform.nvim` for consistent and fast formatting on save.
  - `mason.nvim` for automated management of LSPs and tools.
- **Readability**: Consistent naming conventions, organized settings, and helpful comments throughout the configuration.

## Directory Structure

- `init.lua`: Main entry point.
- `lua/core/`:
  - `options.lua`: General Neovim settings.
  - `keymaps.lua`: Global, non-plugin-specific keybindings.
- `lua/plugins/`:
  - `blink.lua`: Autocompletion setup.
  - `fzf.lua`: Fuzzy finding setup.
  - `lsp.lua`: LSP, Treesitter, Diagnostics, and Formatting.
  - `oil.lua`: File exploration.
  - `ui.lua`: Themes, Statusline, and UI enhancements.
  - `tools.lua`: Task management and utility plugins.
  - `specter.lua`: Global search and replace.

## Custom Features

- `<leader>cc`: Copy current file path and line number to clipboard.
- `<leader>rs`: Open Greyjoy task runner.
- `<leader>fs`: Open Rip-Substitute for regex-based replacement.
- `[e`, `]e`: Jump to previous/next diagnostic error.
- `[t`, `]t`: Jump to previous/next TODO comment.

## Setup

1. Ensure Neovim (0.10+) is installed.
2. Clone this repository to `~/.config/nvim`.
3. Open Neovim; `lazy.nvim` will automatically bootstrap and install the plugins.
4. Run `:Mason` to see the status of LSPs and tools being installed.
