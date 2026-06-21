#!/usr/bin/env bash
set -euo pipefail

WIN_HOME="$(cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')"
WSL_HOME="$(wslpath "$WIN_HOME")"

INSTALL_DIR_WIN="${WIN_HOME}\\Apps\\GlazeWM"
INSTALL_DIR_WSL="$(wslpath "$INSTALL_DIR_WIN")"

TMP_JSON="$(mktemp)"
mkdir -p "$INSTALL_DIR_WSL"

echo "Fetching latest GlazeWM release metadata..."
curl -fsSL "https://api.github.com/repos/glzr-io/glazewm/releases/latest" -o "$TMP_JSON"

ASSET_URL="$(
python3 - "$TMP_JSON" <<'PY'
import json, re, sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
assets = data.get("assets", [])

patterns = [
    r"standalone-glazewm-.*-x64\.msi$",
    r"glazewm-.*-x64\.msi$",
]

for pattern in patterns:
    for asset in assets:
        name = asset.get("name", "")
        if re.search(pattern, name):
            print(asset["browser_download_url"])
            sys.exit(0)

print("No matching GlazeWM x64 MSI asset found.", file=sys.stderr)
print("Available assets:", file=sys.stderr)
for asset in assets:
    print("  -", asset.get("name", ""), file=sys.stderr)
sys.exit(1)
PY
)"

MSI_NAME="$(basename "$ASSET_URL")"
MSI_WSL="$WSL_HOME/Downloads/$MSI_NAME"
MSI_WIN="$(wslpath -w "$MSI_WSL")"

echo "Downloading $MSI_NAME..."
curl -fL "$ASSET_URL" -o "$MSI_WSL"

echo "Extracting MSI into $INSTALL_DIR_WIN without admin..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "\
  \$ErrorActionPreference = 'Stop'; \
  New-Item -ItemType Directory -Force -Path '$INSTALL_DIR_WIN' | Out-Null; \
  Start-Process msiexec.exe -Wait -ArgumentList @('/a', '$MSI_WIN', '/qb', 'TARGETDIR=$INSTALL_DIR_WIN')"

echo "Finding extracted glazewm.exe..."
GWM_EXE_WIN="$(
powershell.exe -NoProfile -Command "\
  Get-ChildItem -Path '$INSTALL_DIR_WIN' -Recurse -Filter glazewm.exe | \
  Select-Object -First 1 -ExpandProperty FullName" | tr -d '\r'
)"

if [ -z "$GWM_EXE_WIN" ]; then
  echo "Could not find glazewm.exe after extraction."
  exit 1
fi

echo "Starting GlazeWM: $GWM_EXE_WIN"
powershell.exe -NoProfile -Command "Start-Process '$GWM_EXE_WIN' -ArgumentList 'start'"
