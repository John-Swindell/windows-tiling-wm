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

ZEBAR_EXE_WIN="$(find_windows_exe "$ZEBAR_INSTALL_ROOT_WIN" 'zebar.exe')"
if [[ -n "$ZEBAR_EXE_WIN" ]]; then
  export ZEBAR_EXE_WIN
  if [[ ! -f "$ZEBAR_INSTALL_ROOT_WSL/$WINWM_DIR_MARKER" ]]; then
    warn "Using existing unmarked Zebar install. Destroy will keep it unless --force is passed: $ZEBAR_INSTALL_ROOT_WIN"
  else
    record_manifest "$ZEBAR_INSTALL_ROOT_WIN" dir "-"
  fi
  write_state_env
  log "Zebar already installed: $ZEBAR_EXE_WIN"
  exit 0
fi

backup_dir_if_unmanaged "$ZEBAR_INSTALL_ROOT_WSL"
mkdir -p "$ZEBAR_INSTALL_ROOT_WSL"

asset_wsl="$(download_github_release_asset 'glzr-io' 'zebar' "$ZEBAR_VERSION" '^zebar-.*x64.*\.msi$' "$(cache_dir)")"
asset_win="$(to_win_path "$asset_wsl")"

log "Extracting Zebar $ZEBAR_VERSION to $ZEBAR_INSTALL_ROOT_WIN"
msiexec_admin_extract "$asset_win" "$ZEBAR_INSTALL_ROOT_WIN"
write_managed_dir_marker "$ZEBAR_INSTALL_ROOT_WSL"

ZEBAR_EXE_WIN="$(find_windows_exe "$ZEBAR_INSTALL_ROOT_WIN" 'zebar.exe')"
[[ -n "$ZEBAR_EXE_WIN" ]] || die "Could not find zebar.exe after MSI extraction"

export ZEBAR_EXE_WIN
write_state_env
record_manifest "$ZEBAR_INSTALL_ROOT_WIN" dir "-"

log "Zebar installed: $ZEBAR_EXE_WIN"
