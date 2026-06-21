# Troubleshooting

## Preflight Fails

Run:

```bash
./bin/winwm doctor
```

The scripts must run from WSL and need `curl`, `python3`, `wslpath`, `cmd.exe`, `powershell.exe`, and `msiexec.exe` through PowerShell.

## GitHub Download Fails

The install modules use the GitHub releases API and pinned tags from `versions.lock`. If corporate networking blocks GitHub, download the matching MSI another way and place it in `cache/`; the asset filename still needs to match the expected release asset.

Expected asset patterns:

```text
GlazeWM: ^standalone-glazewm-.*x64.*\.msi$
Zebar:   ^zebar-.*x64.*\.msi$
```

## Zebar Starts But The Bar Is Missing

Open the Zebar tray icon and check `bamin.bar` / `topbar`. The pack is deployed to:

```text
%USERPROFILE%\.glzr\zebar\bamin.bar
```

If Zebar logs WebView2 errors, the machine may need the Microsoft Edge WebView2 runtime. That is outside this repo because many work machines control it through IT policy.

## GlazeWM Starts Without Gaps For The Bar

Rerun:

```bash
./bin/winwm restart
```

The rendered GlazeWM config reserves a `40px` top outer gap. If you change the Zebar height, update `outer_gap.top` in [config/glazewm/config.yaml.tmpl](../config/glazewm/config.yaml.tmpl).

## Destroy Refuses To Delete Something

Destroy only removes managed files and marked directories by default.

```bash
./destroy.sh --force
```

Use `--force` only after checking the path printed in the warning.
