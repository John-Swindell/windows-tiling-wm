#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"

load_state_if_exists
ensure_windows_paths

ZEBAR_EXE_WIN="$(resolve_zebar_exe)" || die "Could not resolve zebar.exe. Run ./bin/winwm apply first."
export ZEBAR_EXE_WIN
write_state_env

if is_process_running zebar.exe; then
  log "zebar.exe is already running"
  exit 0
fi

log "Starting Zebar: $ZEBAR_EXE_WIN"
start_windows_process "$ZEBAR_EXE_WIN"
sleep 1

is_process_running zebar.exe || die "Zebar did not appear to start"
log "zebar.exe is running"
