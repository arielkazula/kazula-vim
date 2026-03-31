#!/usr/bin/env bash
# Oracle Linux 8: Neovim + C++ Dev Environment (no Postgres, no gtest)
# Run as a regular user; the script uses sudo where required.
#set -euo pipefail

########################################
# Config (override via env if desired)
########################################
: "${CUSTOM_CONFIG_REPO:=https://github.com/arielkazula/kazula-vim.git}"
: "${GO_VERSION:=1.21.1}"                 # target minimum Go version
: "${REQUIRED_NVIM_VERSION:=0.11.4}"      # minimum Neovim version to keep/skip
: "${LUAROCKS_VERSION:=3.9.1}"            # minimum LuaRocks version to keep/skip

# Derived
USER_NAME="$(id -un)"
USER_HOME="$HOME"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-${USER_HOME}/.config/nvim}"
CUSTOM_CONFIG_DIR="${CUSTOM_CONFIG_DIR:-${USER_HOME}/my-nvim-config}"
NVIM_DATA_DIR="${NVIM_DATA_DIR:-${USER_HOME}/.local/share/nvim}"
PROFILE_SNIPPET="${USER_HOME}/.bashrc"   # append env/aliases here

########################################
# Helpers
########################################
log(){ printf '[INFO] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
die(){ printf '[ERR ] %s\n' "$*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

# version compare: ver_ge A B => true if A >= B
ver_ge() { [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# extract only numbers+dots (e.g., v18.19.1 -> 18.19.1)
digits_only() { sed -E 's/[^0-9.]+//g'; }

ensure_ol8() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    if [[ "${ID:-}" != "ol" && "${ID_LIKE:-}" != *"rhel"* ]]; then
      warn "Not Oracle/RHEL-like; continuing anyway."
    fi
    if [[ "${VERSION_ID:-}" != 8* ]]; then
      warn "Not Oracle Linux 8; continuing anyway."
    fi
  else
    warn "/etc/os-release missing; continuing."
  fi
}

SUDO="sudo"
[[ $EUID -eq 0 ]] && SUDO=""

dnf_install() {
  $SUDO dnf -y --setopt=install_weak_deps=False --best install "$@"
}

dnf_groupinstall() {
  $SUDO dnf -y --setopt=install_weak_deps=False --best groupinstall "$@"
}

########################################
# Repos & prerequisites
########################################
enable_repos() {
  log "Installing dnf plugins and enabling EPEL, CodeReady/Builder"
  dnf_install dnf-plugins-core
  # EPEL for OL8
  $SUDO dnf -y install oracle-epel-release-el8
  # CodeReady/Builder (provides many *-devel libs)
  $SUDO dnf config-manager --enable ol8_codeready_builder || true
  $SUDO dnf makecache -y
}

########################################
# Packages (no Postgres, no gtest)
########################################
install_tooling() {
  log "Installing Development Tools group"
  dnf_groupinstall "Development Tools"

  log "Installing base & dev packages"
  dnf_install \
    curl git wget which \
    tmux htop nano \
    tar unzip rsync xclip \
    ripgrep fd-find fzf bat\
    clang-tools-extra-7.0.1-1.0.1.module+el8+5208+f6f800eb.x86_64

  # Optional Python neovim RPM (pip will also install pynvim for user)
  $SUDO dnf -y install python3-neovim || true
}

install_node18() {
  # Skip if node >= 18 already present
  if command -v node >/dev/null 2>&1; then
    local cur
    cur="$(node --version 2>/dev/null | digits_only)"
    if [[ -n "$cur" ]] && ver_ge "$cur" "18.0.0"; then
      log "Node.js >= 18 detected (${cur}); skipping Node module enable/install."
      return 0
    fi
  fi
  log "Enabling Node.js 18 module and installing nodejs"
  $SUDO dnf -y module reset nodejs || true
  $SUDO dnf -y module enable nodejs:18
  dnf_install nodejs
}

install_go() {
  # Skip if go >= GO_VERSION already present
  if command -v go >/dev/null 2>&1; then
    local cur
    cur="$(go version 2>/dev/null | sed -n 's/.* go\([0-9.]\+\).*/\1/p')"
    if [[ -n "$cur" ]] && ver_ge "$cur" "$GO_VERSION"; then
      log "Go ${cur} detected (>= ${GO_VERSION}); skipping download."
      return 0
    fi
  fi

  log "Installing Go ${GO_VERSION} to /usr/local"
  need_cmd curl
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  curl -L "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "${tmp}/go.tgz"
  $SUDO rm -rf /usr/local/go
  $SUDO tar -C /usr/local -xzf "${tmp}/go.tgz"

  # User-scoped env (guarded, idempotent)
  if ! grep -q '### dev-env: go ###' "${PROFILE_SNIPPET}"; then
    cat >> "${PROFILE_SNIPPET}" <<'EOF'

### dev-env: go ###
export GOPATH="${HOME}/go"
export PATH="/usr/local/go/bin:${PATH}"
export PATH="${GOPATH}/bin:${PATH}"
### /dev-env: go ###
EOF
  fi
}

install_luarocks() {
  # Skip if luarocks >= LUAROCKS_VERSION already present
  if command -v luarocks >/dev/null 2>&1; then
    local cur
    cur="$(luarocks --version 2>/dev/null | sed -n 's/^LuaRocks \([0-9.]\+\).*/\1/p')"
    if [[ -n "$cur" ]] && ver_ge "$cur" "$LUAROCKS_VERSION"; then
      log "LuaRocks ${cur} detected (>= ${LUAROCKS_VERSION}); skipping build."
      return 0
    fi
  fi

  log "Installing LuaRocks ${LUAROCKS_VERSION} (OL8 autodetect: LuaJIT 5.1 or Lua 5.3)"

  # Ensure Lua headers
  if ! command -v lua >/dev/null 2>&1; then
    $SUDO dnf -y install lua lua-devel || true
  fi
  if command -v luajit >/dev/null 2>&1 && [ ! -f /usr/include/luajit-2.1/lua.h ]; then
    $SUDO dnf -y install luajit-devel || true
  fi

  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  pushd "$tmp" >/dev/null
  curl -LO "https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz"
  tar xf "luarocks-${LUAROCKS_VERSION}.tar.gz"
  cd "luarocks-${LUAROCKS_VERSION}"

  if [ -f /usr/include/luajit-2.1/lua.h ]; then
    ./configure \
      --with-lua=/usr \
      --with-lua-include=/usr/include/luajit-2.1 \
      --with-lua-lib=/usr/lib64 \
      --with-lua-interpreter=luajit \
      --lua-version=5.1
  else
    local INC=
    if   [ -f /usr/include/lua5.3/lua.h ]; then INC=/usr/include/lua5.3
    elif [ -f /usr/include/lua-5.3/lua.h ]; then INC=/usr/include/lua-5.3
    elif [ -f /usr/include/lua.h ]; then INC=/usr/include
    else die "Lua headers not found. Install with: sudo dnf -y install lua lua-devel"
    fi
    ./configure \
      --with-lua=/usr \
      --with-lua-include="$INC" \
      --with-lua-lib=/usr/lib64 \
      --with-lua-interpreter=lua \
      --lua-version=5.3
  fi

  make
  $SUDO make install
  popd >/dev/null
}

install_neovim_user() {
  # --- Config ---
  local tag="${NEOVIM_TAG:-v0.11.4}"                  # release tag from neovim/neovim-releases
  local min_required="${REQUIRED_NVIM_VERSION:-0.11.4}"
  local base="https://github.com/neovim/neovim-releases/releases/download/${tag}"
  local tar_url="${base}/nvim-linux-x86_64.tar.gz"
  local app_url="${base}/nvim-linux-x86_64.appimage"
  local home="${HOME}"
  local nvim_home="${NVIM_HOME:-$home/.local/nvim-linux64}"

  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  mkdir -p "$home/.local"

  local cur=""
  if command -v nvim >/dev/null 2>&1; then
    cur="$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9.]*\).*/\1/p')"
  fi

  if [[ -n "$cur" ]] && ver_ge "$cur" "$min_required"; then
    log "Neovim ${cur} detected (>= ${min_required}); skipping install."
    return 0
  fi

  log "Installing Neovim because current='${cur:-none}' < required='${min_required}'"

  url_ok() { curl -fsIL --retry 2 --retry-delay 1 "$1" >/dev/null 2>&1; }

  local installed_via=""
  if url_ok "$tar_url"; then
    log "Downloading Neovim tarball: $tar_url"
    if curl -fL --retry 3 --retry-delay 2 -o "$tmp/nvim.tgz" "$tar_url"; then
      if gzip -t "$tmp/nvim.tgz"; then
        local topdir; topdir="$(tar -tzf "$tmp/nvim.tgz" 2>/dev/null | head -n1 | cut -d/ -f1)"
        [[ -z "$topdir" ]] && die "Tarball malformed."
        rm -rf "${nvim_home}.new" "$nvim_home"
        tar -C "$tmp" -xzf "$tmp/nvim.tgz"
        mv "$tmp/$topdir" "${nvim_home}.new"
        mv "${nvim_home}.new" "$nvim_home"
        installed_via="tarball"
      fi
    fi
  fi

  if [[ -z "$installed_via" ]] && url_ok "$app_url"; then
    log "Downloading Neovim AppImage: $app_url"
    if curl -fL --retry 3 --retry-delay 2 -o "$tmp/nvim.appimage" "$app_url"; then
      chmod +x "$tmp/nvim.appimage"
      "$tmp/nvim.appimage" --appimage-extract >/dev/null
      rm -rf "$nvim_home"
      mv squashfs-root "$nvim_home"
      installed_via="appimage"
    fi
  fi

  if [[ -z "$installed_via" ]]; then
    warn "Could not install Neovim (tarball/appimage failed)."
    return 1
  fi

  log "Neovim installed via: ${installed_via} -> ${nvim_home}"
  # Note: keeping any PATH edits you may already have; no config PATH hacks here.
}

install_lazygit() {
  # Skip if lazygit exists at all (keep it simple & stable)
  if command -v lazygit >/dev/null 2>&1; then
    log "LazyGit already installed; skipping."
    return 0
  fi

  log "Installing LazyGit (latest release)"
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  pushd "$tmp" >/dev/null
  need_cmd grep
  local ver
  ver="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name":\s*"v\K[^"]+')"
  curl -L -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  $SUDO install -m 0755 lazygit /usr/local/bin/lazygit
  popd >/dev/null
}

########################################
# Aliases instead of symlinks
########################################
add_aliases() {
  log "Adding convenience aliases (no symlinks)"
  # fd-find provides 'fdfind' on EL8; alias fd if fd not present
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    if ! grep -q "alias fd='fdfind'" "${PROFILE_SNIPPET}"; then
      echo "alias fd='fdfind'" >> "${PROFILE_SNIPPET}"
    fi
  fi
}

########################################
# Neovim + config (copy repo into ~/.config/nvim)
########################################
configure_nvim() {
  # Defaults if not set
  NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-$HOME/.config/nvim}"
  CUSTOM_CONFIG_DIR="${CUSTOM_CONFIG_DIR:-$HOME/my-nvim-config}"

  # Tools we rely on
  command -v git   >/dev/null 2>&1 || { echo "[ERR ] git is required"; return 1; }
  command -v rsync >/dev/null 2>&1 || { echo "[ERR ] rsync is required"; return 1; }

  # 1) Backup existing nvim config (idempotent & safe)
  if [ -d "$NVIM_CONFIG_DIR" ]; then
    local bak="${NVIM_CONFIG_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$NVIM_CONFIG_DIR" "$bak"
    echo "[INFO] Backed up previous config to: $bak"
  fi

  # 2) Fresh clone of LazyVim/starter into ~/.config/nvim
  echo "[INFO] Cloning Config Repo into ${NVIM_CONFIG_DIR}"
  git clone  ${CUSTOM_CONFIG_REPO} "$NVIM_CONFIG_DIR"


  echo "[SUCCESS] Neovim configuration is ready at ${NVIM_CONFIG_DIR} (copy-only, no symlinks, no git)."
}



########################################
# Main
########################################
main() {
  need_cmd sudo
  need_cmd dnf
  need_cmd git
  ensure_ol8

  enable_repos
  install_tooling
  install_node18
  install_go
  install_luarocks
  install_lazygit
  install_neovim_user
  add_aliases
  configure_nvim

  log "Done."
  log "Open a new shell (or 'source ~/.bashrc') to load PATH/aliases."
}

main "$@"
