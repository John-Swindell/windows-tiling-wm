#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/manifest.sh"

force=false
has_arg --force "$@" && force=true

load_state_if_exists
ensure_windows_paths

if [[ -f "${ZEBAR_SETTINGS_WSL:-}" ]]; then
  settings_tmp="$(mktemp)"
  python3 - "$ZEBAR_SETTINGS_WSL" "$settings_tmp" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
tmp_path = Path(sys.argv[2])

try:
    settings = json.loads(settings_path.read_text(encoding="utf-8"))
except json.JSONDecodeError:
    raise SystemExit(0)

if not isinstance(settings, dict):
    raise SystemExit(0)

startup_configs = settings.get("startupConfigs")
if not isinstance(startup_configs, list):
    raise SystemExit(0)

settings["startupConfigs"] = [
    config
    for config in startup_configs
    if not (
        isinstance(config, dict)
        and config.get("pack") == "bamin.bar"
        and config.get("widget") == "topbar"
    )
]

tmp_path.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
PY
  if [[ -s "$settings_tmp" ]]; then
    mv "$settings_tmp" "$ZEBAR_SETTINGS_WSL"
    log "Removed bamin.bar startup config from $ZEBAR_SETTINGS_WSL"
  else
    rm -f "$settings_tmp"
  fi
  manifest_remove_path "$ZEBAR_SETTINGS_WIN::startupConfigs[bamin.bar/topbar]"
fi

remove_managed_file "$GLAZEWM_CONFIG_WSL" "$force"
manifest_remove_path "$GLAZEWM_CONFIG_WIN"

remove_managed_dir "$ZEBAR_PACK_WSL" "$force"
manifest_remove_path "$ZEBAR_PACK_WIN"
