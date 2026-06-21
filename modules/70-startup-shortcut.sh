#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/powershell.sh"

load_state_if_exists
ensure_windows_paths

startup_dir_win="$(windows_startup_dir_win || true)"
if [[ -z "$startup_dir_win" ]]; then
  warn "Could not resolve Windows Startup folder. Skipping startup shortcut."
  exit 0
fi

STARTUP_SHORTCUT_WIN="$startup_dir_win\\WinWM Apply.lnk"
STARTUP_SHORTCUT_WSL="$(to_wsl_path "$STARTUP_SHORTCUT_WIN")"
export STARTUP_SHORTCUT_WIN STARTUP_SHORTCUT_WSL

script_win="$(to_win_path "$ROOT/scripts/windows-start.ps1")"

if create_startup_shortcut "$STARTUP_SHORTCUT_WIN" "$script_win" "$ROOT"; then
  record_manifest "$STARTUP_SHORTCUT_WIN" file "-"
  write_state_env
  log "Startup shortcut created: $STARTUP_SHORTCUT_WIN"
else
  warn "Could not create startup shortcut. Continuing without startup integration."
fi
