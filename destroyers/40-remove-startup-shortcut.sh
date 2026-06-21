#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/powershell.sh"
source "$ROOT/lib/manifest.sh"

force=false
has_arg --force "$@" && force=true

load_state_if_exists
ensure_windows_paths

if [[ -z "${STARTUP_SHORTCUT_WIN:-}" ]]; then
  startup_dir_win="$(windows_startup_dir_win || true)"
  if [[ -n "$startup_dir_win" ]]; then
    STARTUP_SHORTCUT_WIN="$startup_dir_win\\WinWM Apply.lnk"
  fi
fi

[[ -n "${STARTUP_SHORTCUT_WIN:-}" ]] || exit 0

if windows_path_exists "$STARTUP_SHORTCUT_WIN"; then
  if [[ "$force" == "true" ]] || manifest_has_path "$STARTUP_SHORTCUT_WIN" || shortcut_is_managed "$STARTUP_SHORTCUT_WIN"; then
    powershell "Remove-Item -LiteralPath $(ps_quote "$STARTUP_SHORTCUT_WIN") -Force" >/dev/null
    manifest_remove_path "$STARTUP_SHORTCUT_WIN"
    log "Removed startup shortcut: $STARTUP_SHORTCUT_WIN"
  else
    warn "Refusing to remove unrecorded startup shortcut: $STARTUP_SHORTCUT_WIN"
  fi
fi
