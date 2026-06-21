#!/usr/bin/env bash

if [[ -n "${WINWM_GITHUB_SH_LOADED:-}" ]]; then
  return 0
fi
WINWM_GITHUB_SH_LOADED=1

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

download_github_release_asset() {
  local owner="$1"
  local repo="$2"
  local tag="$3"
  local asset_regex="$4"
  local dest_dir="$5"

  need_cmd curl
  need_cmd python3

  mkdir -p "$dest_dir"

  local api metadata metadata_tmp
  api="https://api.github.com/repos/$owner/$repo/releases/tags/$tag"
  metadata="$dest_dir/$owner-$repo-$tag.release.json"
  metadata_tmp="$metadata.tmp"

  local curl_args=(-fsSL -H 'Accept: application/vnd.github+json')
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  log "Fetching release metadata for $owner/$repo@$tag" >&2
  curl "${curl_args[@]}" "$api" -o "$metadata_tmp"
  mv "$metadata_tmp" "$metadata"

  local asset_info asset_name asset_url
  asset_info="$(
    python3 - "$metadata" "$asset_regex" <<'PY'
import json
import re
import sys

metadata_path, pattern = sys.argv[1], sys.argv[2]
with open(metadata_path, encoding="utf-8") as fh:
    data = json.load(fh)

regex = re.compile(pattern)
for asset in data.get("assets", []):
    name = asset.get("name", "")
    if regex.search(name):
        print(name)
        print(asset["browser_download_url"])
        raise SystemExit(0)

print(f"No release asset matched regex: {pattern}", file=sys.stderr)
print("Available assets:", file=sys.stderr)
for asset in data.get("assets", []):
    print(f"  - {asset.get('name', '')}", file=sys.stderr)
raise SystemExit(1)
PY
  )"

  asset_name="$(printf '%s\n' "$asset_info" | sed -n '1p')"
  asset_url="$(printf '%s\n' "$asset_info" | sed -n '2p')"
  [[ -n "$asset_name" && -n "$asset_url" ]] || die "Could not resolve release asset for $owner/$repo@$tag"

  local dest partial
  dest="$dest_dir/$asset_name"
  partial="$dest.partial"

  if [[ -s "$dest" ]]; then
    log "Using cached asset $dest" >&2
    printf '%s\n' "$dest"
    return 0
  fi

  log "Downloading $asset_name" >&2
  curl -fL "$asset_url" -o "$partial"
  mv "$partial" "$dest"
  printf '%s\n' "$dest"
}
