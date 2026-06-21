#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"

load_state_if_exists
ensure_windows_paths

src_dir="$ROOT/config/zebar/bamin.bar"
[[ -d "$src_dir" ]] || die "Missing Zebar widget pack source: $src_dir"

backup_dir_if_unmanaged "$ZEBAR_PACK_WSL"
mkdir -p "$ZEBAR_PACK_WSL"
write_managed_dir_marker "$ZEBAR_PACK_WSL"

shopt -s nullglob
for src in "$src_dir"/*; do
  [[ -f "$src" ]] || continue

  name="$(basename "$src")"
  dest="$ZEBAR_PACK_WSL/$name"
  backup_if_unmanaged "$dest"
  cp "$src" "$dest"

  record_manifest "$ZEBAR_PACK_WIN\\$name" file "$(sha256_file "$dest")"
done
shopt -u nullglob

record_manifest "$ZEBAR_PACK_WIN" dir "-"

settings_tmp="$(mktemp)"
python3 - "$ZEBAR_SETTINGS_WSL" "$settings_tmp" <<'PY'
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

settings_path = Path(sys.argv[1])
tmp_path = Path(sys.argv[2])

startup_config = {
    "pack": "bamin.bar",
    "widget": "topbar",
    "preset": "default",
}

if settings_path.exists():
    try:
        settings = json.loads(settings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        backup = settings_path.with_name(
            f"{settings_path.name}.bak.{datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}"
        )
        shutil.move(settings_path, backup)
        settings = {}
else:
    settings = {}

if not isinstance(settings, dict):
    settings = {}

startup_configs = settings.get("startupConfigs")
if not isinstance(startup_configs, list):
    startup_configs = []

next_startup_configs = []
updated = False

for config in startup_configs:
    if not isinstance(config, dict):
        next_startup_configs.append(config)
        continue

    if config.get("pack") == startup_config["pack"] and config.get("widget") == startup_config["widget"]:
        merged = dict(config)
        merged["preset"] = startup_config["preset"]
        next_startup_configs.append(merged)
        updated = True
    else:
        next_startup_configs.append(config)

if not updated:
    next_startup_configs.append(startup_config)

settings["startupConfigs"] = next_startup_configs
tmp_path.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
PY
mkdir -p "$(dirname "$ZEBAR_SETTINGS_WSL")"
mv "$settings_tmp" "$ZEBAR_SETTINGS_WSL"
record_manifest "$ZEBAR_SETTINGS_WIN::startupConfigs[bamin.bar/topbar]" json-entry "-"

create_wsl_link "$HOME/.config/winwm/live/zebar" "$ZEBAR_ROOT_WSL" || true
write_state_env

cat <<EOF
Zebar widget pack deployed:
  Windows: $ZEBAR_PACK_WIN
  WSL:     $ZEBAR_PACK_WSL

WSL edit link:
  $HOME/.config/winwm/live/zebar -> $ZEBAR_ROOT_WSL
EOF
