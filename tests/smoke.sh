#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r script; do
  bash -n "$script"
done < <(
  find \
    "$ROOT/bin" \
    "$ROOT/lib" \
    "$ROOT/modules" \
    "$ROOT/destroyers" \
    -type f \
    -print | sort
)

bash -n "$ROOT/apply.sh"
bash -n "$ROOT/destroy.sh"

python3 -m json.tool "$ROOT/config/zebar/bamin.bar/zpack.json" >/dev/null

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

required = [
    root / "versions.lock",
    root / "config/glazewm/config.yaml.tmpl",
    root / "config/zebar/bamin.bar/index.html",
    root / "config/zebar/bamin.bar/styles.css",
    root / "config/zebar/bamin.bar/main.js",
]

for path in required:
    text = path.read_text(encoding="utf-8")
    has_marker = (
        "managed-by: winwm-dotfiles" in text
        or "managed-by: __MANAGED_BY__" in text
    )
    if not has_marker and path.name != "versions.lock":
        raise SystemExit(f"missing managed marker: {path}")

template = (root / "config/glazewm/config.yaml.tmpl").read_text(encoding="utf-8")
for placeholder in ["__ZEBAR_EXE_WIN__", "__WIN_TERMINAL_CMD__", "__MANAGED_BY__"]:
    if placeholder not in template:
        raise SystemExit(f"missing template placeholder: {placeholder}")
PY

printf 'smoke checks passed\n'
