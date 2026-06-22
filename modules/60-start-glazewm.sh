#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"

restart=false
for arg in "$@"; do
  case "$arg" in
    --restart) restart=true ;;
    -h|--help)
      printf 'Usage: %s [--restart]\n' "$0"
      exit 0
      ;;
    *) die "Unknown GlazeWM start option: $arg" ;;
  esac
done

load_state_if_exists
ensure_windows_paths

GLAZEWM_EXE_WIN="$(resolve_glazewm_exe)" || die "Could not resolve glazewm.exe. Run ./bin/winwm apply first."
export GLAZEWM_EXE_WIN
write_state_env

[[ -f "$GLAZEWM_CONFIG_WSL" ]] || die "Missing GlazeWM live config: $GLAZEWM_CONFIG_WSL"

restart_flag="$(state_dir)/restart-glazewm"

if is_process_running glazewm.exe; then
  if [[ "$restart" == "true" || -f "$restart_flag" ]]; then
    log "Restarting GlazeWM to load deployed config"
    taskkill_if_running glazewm.exe
    rm -f "$restart_flag"
    sleep 1
  else
    log "glazewm.exe is already running"
    exit 0
  fi
fi

rm -f "$restart_flag"

log "Starting GlazeWM: $GLAZEWM_EXE_WIN"
start_windows_process "$GLAZEWM_EXE_WIN" "start --config=\"$GLAZEWM_CONFIG_WIN\""
sleep 2

is_process_running glazewm.exe || die "GlazeWM did not appear to start"
log "glazewm.exe is running"
