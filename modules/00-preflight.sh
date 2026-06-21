#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
  [[ -e /proc/sys/fs/binfmt_misc/WSLInterop ]] && return 0
  grep -qi microsoft /proc/version 2>/dev/null
}

is_wsl || die "This repo must be run from WSL"

need_cmd curl
need_cmd python3
need_cmd wslpath
need_cmd powershell.exe
need_cmd cmd.exe

powershell "Get-Command msiexec.exe -ErrorAction Stop | Out-Null" >/dev/null \
  || die "msiexec.exe is not callable through PowerShell"

[[ -f "$(versions_file)" ]] || die "Missing versions.lock"
load_versions
ensure_windows_paths

[[ -d "$WIN_HOME_WSL" ]] || die "Windows user profile is not visible from WSL: $WIN_HOME_WSL"
[[ -w "$WIN_HOME_WSL" ]] || die "Windows user profile is not writable from WSL: $WIN_HOME_WSL"
[[ -d "$(repo_root)" ]] || die "Repo root cannot be resolved"

mkdir -p "$(state_dir)" "$(cache_dir)"
write_state_env

cat <<EOF
Windows home:
  $WIN_HOME_WIN

WSL view:
  $WIN_HOME_WSL

App root:
  $WINWM_APP_ROOT_WIN

GlazeWM live config:
  $GLAZEWM_CONFIG_WIN

Zebar live root:
  $ZEBAR_ROOT_WIN
EOF
