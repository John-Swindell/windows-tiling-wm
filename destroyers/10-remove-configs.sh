#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/manifest.sh"

force=false
has_arg --force "$@" && force=true

load_state_if_exists
ensure_windows_paths

remove_managed_file "$GLAZEWM_CONFIG_WSL" "$force"
manifest_remove_path "$GLAZEWM_CONFIG_WIN"

remove_managed_dir "$ZEBAR_PACK_WSL" "$force"
manifest_remove_path "$ZEBAR_PACK_WIN"
