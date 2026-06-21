#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"

load_state_if_exists
ensure_windows_paths

src_dir="$ROOT/config/zebar/bamin.bar"
[[ -d "$src_dir" ]] || die "Missing Zebar widget pack source: $src_dir"

backup_dir_if_unmanaged "$ZEBAR_PACK_WSL"
mkdir -p "$ZEBAR_PACK_WSL"
write_managed_dir_marker "$ZEBAR_PACK_WSL"

shopt -s nullglob
for src in "$src_dir"/*; do
  [[ -f "$src" ]] || continue

  name="$(basename "$src")"
  dest="$ZEBAR_PACK_WSL/$name"
  backup_if_unmanaged "$dest"
  cp "$src" "$dest"

  record_manifest "$ZEBAR_PACK_WIN\\$name" file "$(sha256_file "$dest")"
done
shopt -u nullglob

record_manifest "$ZEBAR_PACK_WIN" dir "-"

create_wsl_link "$HOME/.config/winwm/live/zebar" "$ZEBAR_ROOT_WSL" || true
write_state_env

cat <<EOF
Zebar widget pack deployed:
  Windows: $ZEBAR_PACK_WIN
  WSL:     $ZEBAR_PACK_WSL

WSL edit link:
  $HOME/.config/winwm/live/zebar -> $ZEBAR_ROOT_WSL
EOF
