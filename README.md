# Kazula-Vim Modernized (2025)

Welcome to your refined, ultra-fast, and modular Neovim environment. This configuration is built for performance, intelligence, and ease of use.

## 🚀 The Core Tools

- **Completion**: `blink.cmp` (Rust-powered, extremely fast).
- **Fuzzy Finder**: `fzf-lua` (Faster alternative to Telescope).
- **Navigation**: `flash.nvim` (Jump anywhere instantly).
- **LSP**: Integrated with `mason.nvim` and optimized flags for `clangd`.
- **UI**: `snacks.nvim` suite (Dashboard, Notifier, Indent guides).
- **Session**: `persistence.nvim` (Auto-saves your workspace).
- **File Explorer**: `oil.nvim` (Edit your files like a buffer).

---

## ⌨️ Essential Keymaps (Non-Leader)

These are the core Vim-style commands enhanced by your new tools:

### 1. Navigation & Motion
- `s` : **Flash Jump** — Type 2 letters to jump anywhere on the screen.
- `S` : **Flash Treesitter** — Select blocks of code (functions, loops) instantly.
- `H`, `L` : (Reserved for specialized movement or custom logic).
- `<C-h/j/k/l>` : **Smart Splits** — Move seamlessly between Neovim splits.
- `<A-[>` / `<A-]>` : **Buffer Switch** — Jump to the previous/next open file.

### 2. Code Intelligence (LSP)
- `gd` : **Goto Definition**.
- `grr` : **References** (Opens in FZF for fast filtering).
- `gra` : **Code Actions** (Fixes, imports, etc.).
- `grn` : **Rename** symbol project-wide.
- `gri` : **Implementations**.
- `K` : **Hover Docs** (Shows documentation in a rounded window).
- `[e` / `]e` : Jump to Prev/Next **Error**.
- `[w` / `]w` : Jump to Prev/Next **Warning**.
- `[t` / `]t` : Jump to Prev/Next **TODO** comment.

### 3. File System
- `-` : **Oil Explorer** — Open the current directory as a buffer.

### 4. Editing QoL
- `jk` or `jj` : **Fast Escape** — Exit insert mode without reaching for `Esc`.
- `<C-a>` / `<C-x>` : **Smart Dial** — Toggles `true` ⇄ `false`, increments dates, hex colors, and versions.
- `gs` : **Surround** — Use `gsa` (add), `gsd` (delete), `gsr` (replace) for brackets/quotes.

---

## 🛠️ Leader Mappings (`<Space>`)

Press `<leader>` and wait 1 second; **Which-Key** will pop up and show you everything!

### Quick Highlights:
- `<leader><leader>` : Search Files (FZF).
- `<leader>rs` : **Run Task** (Overseer) — Python, C++ builds, Docker.
- `<leader>sr` : **Search & Replace** (Grug-Far) — Project-wide search.
- `<leader>qs` : **Restore Session** — Reopen exactly where you left off.
- `<leader>cc` : **Copy Path** — Copies `file:line` to clipboard.

---

## 📂 Configuration Structure

- `init.lua` : Entry point.
- `lua/core/` : Settings, Autocommands, and ALL Keymaps.
- `lua/plugins/` : Modular plugin definitions (Granular & documented).
- `lua/overseer/` : Your custom background task templates.
