# Paths

## Repo Paths

| Path | Purpose |
| --- | --- |
| `versions.lock` | Pinned GlazeWM and Zebar release tags |
| `config/glazewm/config.yaml.tmpl` | Source GlazeWM config template |
| `config/zebar/bamin.bar/` | Source Zebar widget pack |
| `state/paths.env` | Generated machine-specific paths |
| `state/manifest.tsv` | Generated deployment manifest |
| `cache/` | Downloaded GitHub release assets |

## Windows Live Paths

| Path | Purpose |
| --- | --- |
| `%USERPROFILE%\.glzr\glazewm\config.yaml` | Live GlazeWM config |
| `%USERPROFILE%\.glzr\zebar\bamin.bar` | Live Zebar widget pack |
| `%USERPROFILE%\Apps\WinWM\glazewm\<version>` | Extracted GlazeWM app files |
| `%USERPROFILE%\Apps\WinWM\zebar\<version>` | Extracted Zebar app files |

## WSL Convenience Links

| Path | Target |
| --- | --- |
| `~/.config/winwm/live/glazewm` | Windows live GlazeWM config directory |
| `~/.config/winwm/live/zebar` | Windows live Zebar root |

The WSL links are editing conveniences only. Windows does not rely on them.
