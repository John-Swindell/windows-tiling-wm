#!/usr/bin/env bash

if [[ -n "${WINWM_POWERSHELL_SH_LOADED:-}" ]]; then
  return 0
fi
WINWM_POWERSHELL_SH_LOADED=1

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/windows.sh"

create_startup_shortcut() {
  local shortcut_win="$1"
  local script_win="$2"
  local repo_root_wsl="$3"
  local args

  args="-NoProfile -ExecutionPolicy Bypass -File \"$script_win\" -RepoRootWsl \"$repo_root_wsl\""

  powershell "\$ErrorActionPreference = 'Stop'; \$shortcutPath = $(ps_quote "$shortcut_win"); \$scriptPath = $(ps_quote "$script_win"); \$arguments = $(ps_quote "$args"); \$startupDir = Split-Path -Parent \$shortcutPath; New-Item -ItemType Directory -Force -Path \$startupDir | Out-Null; \$shell = New-Object -ComObject WScript.Shell; \$shortcut = \$shell.CreateShortcut(\$shortcutPath); \$shortcut.TargetPath = Join-Path \$env:SystemRoot 'System32\\WindowsPowerShell\\v1.0\\powershell.exe'; \$shortcut.Arguments = \$arguments; \$shortcut.WorkingDirectory = Split-Path -Parent \$scriptPath; \$shortcut.WindowStyle = 7; \$shortcut.Description = 'managed-by: $WINWM_MANAGED_BY'; \$shortcut.Save()"
}

shortcut_is_managed() {
  local shortcut_win="$1"

  powershell "\$path = $(ps_quote "$shortcut_win"); if (-not (Test-Path -LiteralPath \$path)) { exit 1 }; \$shell = New-Object -ComObject WScript.Shell; \$shortcut = \$shell.CreateShortcut(\$path); if (\$shortcut.Description -eq 'managed-by: $WINWM_MANAGED_BY' -or \$shortcut.Arguments -like '*windows-start.ps1*') { exit 0 } exit 1" >/dev/null 2>&1
}
