#!/usr/bin/env bash
set -euo pipefail

WINWM_MODULE_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT/lib/common.sh"
source "$ROOT/lib/windows.sh"
source "$ROOT/lib/render.sh"

load_state_if_exists
ensure_windows_paths

ZEBAR_EXE_WIN="$(resolve_zebar_exe)" || die "Could not resolve zebar.exe. Run modules/10-install-zebar.sh first."
export ZEBAR_EXE_WIN

template="$ROOT/config/glazewm/config.yaml.tmpl"
[[ -f "$template" ]] || die "Missing GlazeWM template: $template"

mkdir -p "$GLAZEWM_LIVE_DIR_WSL"
tmp="$(mktemp)"

render_template "$template" "$tmp" \
  '__ZEBAR_EXE_WIN__' "$ZEBAR_EXE_WIN" \
  '__WIN_TERMINAL_CMD__' 'wt.exe -w 0 new-tab wsl.exe' \
  '__MANAGED_BY__' "$WINWM_MANAGED_BY"

backup_if_unmanaged "$GLAZEWM_CONFIG_WSL"
mv "$tmp" "$GLAZEWM_CONFIG_WSL"

record_manifest "$GLAZEWM_CONFIG_WIN" file "$(sha256_file "$GLAZEWM_CONFIG_WSL")"
create_wsl_link "$HOME/.config/winwm/live/glazewm" "$GLAZEWM_LIVE_DIR_WSL" || true
write_state_env

# A running GlazeWM keeps its old in-memory config, so flag a restart to make
# the start module reload the freshly deployed config.
if is_process_running glazewm.exe; then
  touch "$(state_dir)/restart-glazewm"
fi

cat <<EOF
GlazeWM config deployed:
  Windows: $GLAZEWM_CONFIG_WIN
  WSL:     $GLAZEWM_CONFIG_WSL

WSL edit link:
  $HOME/.config/winwm/live/glazewm -> $GLAZEWM_LIVE_DIR_WSL
EOF
