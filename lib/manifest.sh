#!/usr/bin/env bash

if [[ -n "${WINWM_MANIFEST_SH_LOADED:-}" ]]; then
  return 0
fi
WINWM_MANIFEST_SH_LOADED=1

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

manifest_paths() {
  local file
  file="$(manifest_file)"

  [[ -f "$file" ]] || return 0
  awk -F '\t' '{ print $1 }' "$file"
}

manifest_remove_path() {
  local path="$1"
  local file tmp
  file="$(manifest_file)"

  [[ -f "$file" ]] || return 0
  tmp="$(mktemp)"
  p="$path" awk -F '\t' '$1 != ENVIRON["p"] { print }' "$file" >"$tmp"
  mv "$tmp" "$file"
}
