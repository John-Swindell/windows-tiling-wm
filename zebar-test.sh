#!/usr/bin/env bash
set -euo pipefail

WIN_HOME="$(cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')"
WSL_HOME="$(wslpath "$WIN_HOME")"

ZEBAR_VERSION="v3.3.1"
ZEBAR_MSI="zebar-${ZEBAR_VERSION}-opt1-x64.msi"
ZEBAR_URL="https://github.com/glzr-io/zebar/releases/download/${ZEBAR_VERSION}/${ZEBAR_MSI}"

INSTALL_DIR_WIN="${WIN_HOME}\\Apps\\Zebar"
INSTALL_DIR_WSL="$(wslpath "$INSTALL_DIR_WIN")"

mkdir -p "$INSTALL_DIR_WSL" "$WSL_HOME/Downloads"

echo "Downloading Zebar..."
curl -fL "$ZEBAR_URL" -o "$WSL_HOME/Downloads/$ZEBAR_MSI"

MSI_WIN="$(wslpath -w "$WSL_HOME/Downloads/$ZEBAR_MSI")"

echo "Extracting Zebar MSI without admin..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "\
  \$ErrorActionPreference = 'Stop'; \
  New-Item -ItemType Directory -Force -Path '$INSTALL_DIR_WIN' | Out-Null; \
  Start-Process msiexec.exe -Wait -ArgumentList @('/a', '$MSI_WIN', '/qb', 'TARGETDIR=$INSTALL_DIR_WIN')"

echo "Finding zebar.exe..."
ZEBAR_EXE_WIN="$(
powershell.exe -NoProfile -Command "\
  Get-ChildItem -Path '$INSTALL_DIR_WIN' -Recurse -Filter zebar.exe | \
  Select-Object -First 1 -ExpandProperty FullName" | tr -d '\r'
)"

if [ -z "$ZEBAR_EXE_WIN" ]; then
  echo "Could not find zebar.exe after extraction."
  exit 1
fi

echo "Zebar found at:"
echo "$ZEBAR_EXE_WIN"

echo "Starting Zebar..."
powershell.exe -NoProfile -Command "Start-Process '$ZEBAR_EXE_WIN'"
