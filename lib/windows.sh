#!/usr/bin/env bash

if [[ -n "${WINWM_WINDOWS_SH_LOADED:-}" ]]; then
  return 0
fi
WINWM_WINDOWS_SH_LOADED=1

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

strip_cr() {
  tr -d '\r'
}

ps_quote() {
  local value="${1-}"
  value=${value//\'/\'\'}
  printf "'%s'" "$value"
}

powershell() {
  local command="$1"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$command"
}

win_userprofile_win() {
  cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | strip_cr | sed 's/[[:space:]]*$//'
}

to_win_path() {
  wslpath -w "$1" | strip_cr
}

to_wsl_path() {
  wslpath -u "$1" | strip_cr
}

windows_startup_dir_win() {
  powershell "[Environment]::GetFolderPath('Startup')" | strip_cr | sed 's/[[:space:]]*$//'
}

ensure_windows_paths() {
  load_versions

  WIN_HOME_WIN="$(win_userprofile_win)"
  [[ -n "$WIN_HOME_WIN" ]] || die "Could not resolve Windows user profile"

  WIN_HOME_WSL="$(to_wsl_path "$WIN_HOME_WIN")"
  WINWM_APP_ROOT_WIN="$WIN_HOME_WIN\\Apps\\WinWM"
  WINWM_APP_ROOT_WSL="$(to_wsl_path "$WINWM_APP_ROOT_WIN")"

  GLAZEWM_INSTALL_ROOT_WIN="$WINWM_APP_ROOT_WIN\\glazewm\\$GLAZEWM_VERSION"
  GLAZEWM_INSTALL_ROOT_WSL="$(to_wsl_path "$GLAZEWM_INSTALL_ROOT_WIN")"
  ZEBAR_INSTALL_ROOT_WIN="$WINWM_APP_ROOT_WIN\\zebar\\$ZEBAR_VERSION"
  ZEBAR_INSTALL_ROOT_WSL="$(to_wsl_path "$ZEBAR_INSTALL_ROOT_WIN")"

  GLAZEWM_LIVE_DIR_WIN="$WIN_HOME_WIN\\.glzr\\glazewm"
  GLAZEWM_LIVE_DIR_WSL="$(to_wsl_path "$GLAZEWM_LIVE_DIR_WIN")"
  GLAZEWM_CONFIG_WIN="$GLAZEWM_LIVE_DIR_WIN\\config.yaml"
  GLAZEWM_CONFIG_WSL="$(to_wsl_path "$GLAZEWM_CONFIG_WIN")"

  ZEBAR_ROOT_WIN="$WIN_HOME_WIN\\.glzr\\zebar"
  ZEBAR_ROOT_WSL="$(to_wsl_path "$ZEBAR_ROOT_WIN")"
  ZEBAR_PACK_WIN="$ZEBAR_ROOT_WIN\\bamin.bar"
  ZEBAR_PACK_WSL="$(to_wsl_path "$ZEBAR_PACK_WIN")"

  export WINWM_MANAGED_BY
  export WIN_HOME_WIN WIN_HOME_WSL WINWM_APP_ROOT_WIN WINWM_APP_ROOT_WSL
  export GLAZEWM_INSTALL_ROOT_WIN GLAZEWM_INSTALL_ROOT_WSL
  export ZEBAR_INSTALL_ROOT_WIN ZEBAR_INSTALL_ROOT_WSL
  export GLAZEWM_LIVE_DIR_WIN GLAZEWM_LIVE_DIR_WSL GLAZEWM_CONFIG_WIN GLAZEWM_CONFIG_WSL
  export ZEBAR_ROOT_WIN ZEBAR_ROOT_WSL ZEBAR_PACK_WIN ZEBAR_PACK_WSL
}

find_windows_exe() {
  local root_win="$1"
  local exe_name="$2"

  powershell "\$root = $(ps_quote "$root_win"); if (Test-Path -LiteralPath \$root) { \$match = Get-ChildItem -LiteralPath \$root -Recurse -Filter $(ps_quote "$exe_name") -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName; if (\$match) { [Console]::Out.Write(\$match) } }" | strip_cr
}

windows_path_exists() {
  local path_win="$1"
  powershell "if (Test-Path -LiteralPath $(ps_quote "$path_win")) { exit 0 } exit 1" >/dev/null 2>&1
}

is_process_running() {
  local process_name="${1%.exe}"
  powershell "if (Get-Process -Name $(ps_quote "$process_name") -ErrorAction SilentlyContinue) { exit 0 } exit 1" >/dev/null 2>&1
}

taskkill_if_running() {
  local process_name="${1%.exe}"

  if is_process_running "$process_name"; then
    powershell "Stop-Process -Name $(ps_quote "$process_name") -Force -ErrorAction SilentlyContinue" >/dev/null
    log "Stopped $process_name.exe"
  else
    log "$process_name.exe is not running"
  fi
}

start_windows_process() {
  local exe_win="$1"
  shift

  local exe_literal arg arg_list command
  exe_literal="$(ps_quote "$exe_win")"
  arg_list=""

  for arg in "$@"; do
    if [[ -n "$arg_list" ]]; then
      arg_list+=", "
    fi
    arg_list+="$(ps_quote "$arg")"
  done

  if [[ -n "$arg_list" ]]; then
    command="\$ErrorActionPreference = 'Stop'; Start-Process -FilePath $exe_literal -ArgumentList @($arg_list)"
  else
    command="\$ErrorActionPreference = 'Stop'; Start-Process -FilePath $exe_literal"
  fi

  powershell "$command" >/dev/null
}

msiexec_admin_extract() {
  local msi_win="$1"
  local target_win="$2"

  # msiexec /a cannot open packages over the \\wsl$ / \\wsl.localhost share, so
  # stage the MSI on the real Windows filesystem (%TEMP%) before extracting.
  powershell "\$ErrorActionPreference = 'Stop'; \$src = $(ps_quote "$msi_win"); \$target = $(ps_quote "$target_win"); New-Item -ItemType Directory -Force -Path \$target | Out-Null; \$tmp = Join-Path \$env:TEMP ('winwm-' + [System.IO.Path]::GetFileName(\$src)); Copy-Item -LiteralPath \$src -Destination \$tmp -Force; try { \$p = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @('/a', \$tmp, '/qb', \"TARGETDIR=\$target\"); if (\$p.ExitCode -ne 0) { throw \"msiexec failed with exit code \$(\$p.ExitCode)\" } } finally { Remove-Item -LiteralPath \$tmp -Force -ErrorAction SilentlyContinue }"
}

resolve_zebar_exe() {
  if [[ -n "${ZEBAR_EXE_WIN:-}" ]]; then
    local current_wsl
    current_wsl="$(to_wsl_path "$ZEBAR_EXE_WIN" 2>/dev/null || true)"
    if [[ -n "$current_wsl" && -f "$current_wsl" ]]; then
      printf '%s\n' "$ZEBAR_EXE_WIN"
      return 0
    fi
  fi

  ZEBAR_EXE_WIN="$(find_windows_exe "$ZEBAR_INSTALL_ROOT_WIN" 'zebar.exe')"
  [[ -n "$ZEBAR_EXE_WIN" ]] || return 1
  export ZEBAR_EXE_WIN
  write_state_env
  printf '%s\n' "$ZEBAR_EXE_WIN"
}

resolve_glazewm_exe() {
  if [[ -n "${GLAZEWM_EXE_WIN:-}" ]]; then
    local current_wsl
    current_wsl="$(to_wsl_path "$GLAZEWM_EXE_WIN" 2>/dev/null || true)"
    if [[ -n "$current_wsl" && -f "$current_wsl" ]]; then
      printf '%s\n' "$GLAZEWM_EXE_WIN"
      return 0
    fi
  fi

  GLAZEWM_EXE_WIN="$(find_windows_exe "$GLAZEWM_INSTALL_ROOT_WIN" 'glazewm.exe')"
  [[ -n "$GLAZEWM_EXE_WIN" ]] || return 1
  export GLAZEWM_EXE_WIN
  write_state_env
  printf '%s\n' "$GLAZEWM_EXE_WIN"
}

process_status_text() {
  local process_name="$1"

  if is_process_running "$process_name"; then
    printf '%s\n' 'running'
  else
    printf '%s\n' 'not running'
  fi
}
