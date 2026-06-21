# Windows Tiling WM Dotfiles

Bash-first WSL dotfiles for installing and configuring GlazeWM plus Zebar on a locked-down Windows machine without admin rights.

The repo source is the source of truth. Live Windows config is copied into `%USERPROFILE%\.glzr`, and app binaries are extracted from pinned GitHub MSI releases into `%USERPROFILE%\Apps\WinWM`.

## Commands

```bash
./apply.sh
./apply.sh --enable-startup

./bin/winwm status
./bin/winwm paths
./bin/winwm doctor
./bin/winwm restart

./destroy.sh
./destroy.sh --keep-apps
./destroy.sh --purge-cache
./destroy.sh --all-versions --force
```

## What Apply Does

1. Checks that it is running inside WSL and can reach Windows interop commands.
2. Downloads pinned GitHub MSI assets into `cache/`.
3. Extracts those MSIs with `msiexec /a` into `%USERPROFILE%\Apps\WinWM`.
4. Deploys the Zebar widget pack to `%USERPROFILE%\.glzr\zebar\bamin.bar`.
5. Renders GlazeWM config to `%USERPROFILE%\.glzr\glazewm\config.yaml`.
6. Starts Zebar first, then GlazeWM with an explicit `--config` path.

## Safety

Generated files include `managed-by: winwm-dotfiles` markers where the format allows it. Managed directories get a `.managed-by-winwm-dotfiles` marker.

If a live target already exists and is not managed by this repo, apply backs it up to `.bak.<timestamp>` before writing. Destroy refuses to remove unmanaged files unless `--force` is passed.

## Pinned Versions

Versions live in `versions.lock`:

```bash
GLAZEWM_VERSION="v3.10.1"
ZEBAR_VERSION="v3.3.1"
```

Normal apply uses those exact tags. Do not point normal apply at `latest`; bump versions intentionally in a separate change.

## Repository Layout

```text
bin/          Human-facing CLI wrappers
lib/          Shared Bash and PowerShell interop helpers
modules/      Apply steps
destroyers/   Destroy steps
config/       Source GlazeWM and Zebar config
scripts/      Windows-side startup bridge
state/        Generated state, ignored except .gitkeep
cache/        Downloaded release assets, ignored except .gitkeep
docs/         Notes for keybindings, paths, troubleshooting
```

Run `./tests/smoke.sh` for local static checks. It does not install or start Windows apps.
