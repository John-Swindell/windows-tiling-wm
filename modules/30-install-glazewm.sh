#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/github.sh"

load_state_if_exists
ensure_windows_paths

mkdir -p "$(cache_dir)"

GLAZEWM_EXE_WIN="$(find_windows_exe "$GLAZEWM_INSTALL_ROOT_WIN" 'glazewm.exe')"
if [[ -n "$GLAZEWM_EXE_WIN" ]]; then
  export GLAZEWM_EXE_WIN
  if [[ ! -f "$GLAZEWM_INSTALL_ROOT_WSL/$WINWM_DIR_MARKER" ]]; then
    warn "Using existing unmarked GlazeWM install. Destroy will keep it unless --force is passed: $GLAZEWM_INSTALL_ROOT_WIN"
  else
    record_manifest "$GLAZEWM_INSTALL_ROOT_WIN" dir "-"
  fi
  write_state_env
  log "GlazeWM already installed: $GLAZEWM_EXE_WIN"
  exit 0
fi

backup_dir_if_unmanaged "$GLAZEWM_INSTALL_ROOT_WSL"
mkdir -p "$GLAZEWM_INSTALL_ROOT_WSL"

asset_wsl="$(download_github_release_asset 'glzr-io' 'glazewm' "$GLAZEWM_VERSION" '^standalone-glazewm-.*x64.*\.msi$' "$(cache_dir)")"
asset_win="$(to_win_path "$asset_wsl")"

log "Extracting GlazeWM $GLAZEWM_VERSION to $GLAZEWM_INSTALL_ROOT_WIN"
msiexec_admin_extract "$asset_win" "$GLAZEWM_INSTALL_ROOT_WIN"
write_managed_dir_marker "$GLAZEWM_INSTALL_ROOT_WSL"

GLAZEWM_EXE_WIN="$(find_windows_exe "$GLAZEWM_INSTALL_ROOT_WIN" 'glazewm.exe')"
[[ -n "$GLAZEWM_EXE_WIN" ]] || die "Could not find glazewm.exe after MSI extraction"

export GLAZEWM_EXE_WIN
write_state_env
record_manifest "$GLAZEWM_INSTALL_ROOT_WIN" dir "-"

log "GlazeWM installed: $GLAZEWM_EXE_WIN"
