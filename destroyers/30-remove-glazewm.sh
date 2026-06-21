#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/manifest.sh"

force=false
keep_apps=false
all_versions=false
has_arg --force "$@" && force=true
has_arg --keep-apps "$@" && keep_apps=true
has_arg --all-versions "$@" && all_versions=true

load_state_if_exists
ensure_windows_paths

if [[ "$keep_apps" == "true" ]]; then
  log "Keeping GlazeWM app install because --keep-apps was passed"
  exit 0
fi

if [[ "$all_versions" == "true" ]]; then
  parent="$WINWM_APP_ROOT_WSL/glazewm"
  if [[ -d "$parent" ]]; then
    for dir in "$parent"/*; do
      [[ -d "$dir" ]] || continue
      remove_managed_dir "$dir" "$force"
    done
    rmdir "$parent" 2>/dev/null || true
  fi
else
  remove_managed_dir "$GLAZEWM_INSTALL_ROOT_WSL" "$force"
  manifest_remove_path "$GLAZEWM_INSTALL_ROOT_WIN"
  rmdir "$WINWM_APP_ROOT_WSL/glazewm" 2>/dev/null || true
fi
