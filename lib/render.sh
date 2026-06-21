#!/usr/bin/env bash

if [[ -n "${WINWM_RENDER_SH_LOADED:-}" ]]; then
  return 0
fi
WINWM_RENDER_SH_LOADED=1

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

render_template() {
  local template="$1"
  local dest="$2"
  shift 2

  need_cmd python3
  mkdir -p "$(dirname "$dest")"

  python3 - "$template" "$dest" "$@" <<'PY'
from pathlib import Path
import sys

template = Path(sys.argv[1])
dest = Path(sys.argv[2])
pairs = sys.argv[3:]

if len(pairs) % 2 != 0:
    print("render_template requires placeholder/value pairs", file=sys.stderr)
    raise SystemExit(1)

text = template.read_text(encoding="utf-8")
for key, value in zip(pairs[0::2], pairs[1::2]):
    text = text.replace(key, value)

dest.write_text(text, encoding="utf-8", newline="\n")
PY
}
