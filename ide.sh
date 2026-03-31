#!/usr/bin/env bash
###############################################################################
# ide.sh – launch the Neovim-IDE container with persistent data & host X11    #
###############################################################################
set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
IMAGE=${IMAGE:-nvim-ide:latest}
CONTAINER=${CONTAINER:-nvim-ide}

# ─── Workspace arg ───────────────────────────────────────────────────────────
WORKSPACE="${1:-$PWD}"
WORKSPACE=$(realpath "$WORKSPACE")

# ─── Host storage dirs (override via env) ────────────────────────────────────
HOST_DATA="${HOST_DATA:-$HOME/.local/share/nvim-ide}"
HOST_STATE="${HOST_STATE:-$HOME/.local/state/nvim-ide}"
HOST_CACHE="${HOST_CACHE:-$HOME/.cache/nvim-ide}"
HOST_XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"
HOST_CONFIG="${CONFIG:-$HOME/git/kazula_vim}"

# ─── Ensure they exist & Xauthority is readable ─────────────────────────────
mkdir -p "$HOST_DATA" "$HOST_STATE" "$HOST_CACHE"
if [[ ! -r "$HOST_XAUTH" ]]; then
  echo "❌ Cannot read Xauthority: $HOST_XAUTH" >&2
  exit 1
fi

# ─── Diagnostics ──────────────────────────────────────────────────────────────
cat <<EOF
▶ Launching container: $CONTAINER
  Workspace   : $WORKSPACE
  Data (share): $HOST_DATA → /workspace/.local/share/nvim
  State       : $HOST_STATE → /workspace/.local/state
  Cache       : $HOST_CACHE → /workspace/.cache/nvim
  Config      : /opt/nvim-config/nvim  (built-in)
  Image       : $IMAGE
  DISPLAY     : $DISPLAY  (host-network)
EOF

# ─── Run the container ───────────────────────────────────────────────────────
docker run --rm -it \
  --name "$CONTAINER" \
  --network host \
  --user "$(id -u):$(id -g)" \
  -e HOME=/workspace \
  -e DISPLAY="$DISPLAY" \
  -e XAUTHORITY=/workspace/.Xauthority \
  -v "$WORKSPACE":/workspace \
  -v "$HOST_DATA":/workspace/.local/share/nvim \
  -v "$HOST_STATE":/workspace/.local/state \
  -v "$HOST_CACHE":/workspace/.cache/nvim \
  -v "$HOST_XAUTH":/workspace/.Xauthority:ro \
  -v "$HOST_CONFIG":/opt/nvim-config/nvim \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  "$IMAGE" nvim "${@:2}"

