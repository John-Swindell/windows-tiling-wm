# Keybindings

The GlazeWM template follows an i3-style HJKL workflow.

| Binding | Action |
| --- | --- |
| `alt+h/j/k/l` | Focus left/down/up/right |
| `alt+shift+h/j/k/l` | Move window left/down/up/right |
| `alt+r` | Enter resize mode |
| `h/j/k/l` in resize mode | Resize focused window |
| `escape`, `enter`, `alt+r` | Leave resize mode |
| `alt+1..9` | Focus workspace |
| `alt+shift+1..9` | Move window to workspace and follow |
| `alt+a` / `alt+s` | Previous/next active workspace |
| `alt+d` | Recent workspace |
| `alt+v` | Toggle tiling direction |
| `alt+f` | Toggle fullscreen |
| `alt+shift+space` | Toggle centered floating |
| `alt+t` | Toggle tiling |
| `alt+m` | Minimize |
| `alt+shift+q` | Close window |
| `alt+shift+r` | Reload config |
| `alt+shift+w` | Redraw windows |
| `alt+shift+p` | Pause window manager |
| `alt+shift+e` | Exit GlazeWM |
| `alt+enter` | Launch Windows Terminal into WSL |

Edit [config/glazewm/config.yaml.tmpl](../config/glazewm/config.yaml.tmpl), then rerun `./apply.sh`.
