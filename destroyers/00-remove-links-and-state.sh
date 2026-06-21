#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"

force=false
purge_cache=false
has_arg --force "$@" && force=true
has_arg --purge-cache "$@" && purge_cache=true

remove_wsl_link "$HOME/.config/winwm/live/glazewm" "$force"
remove_wsl_link "$HOME/.config/winwm/live/zebar" "$force"

if [[ -d "$(state_dir)" ]]; then
  find "$(state_dir)" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
  log "Cleared state files"
fi

if [[ "$purge_cache" == "true" && -d "$(cache_dir)" ]]; then
  find "$(cache_dir)" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
  log "Purged cache files"
fi
