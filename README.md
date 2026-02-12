# Smart-KDE-Inhibitor

On Manjaro Linux with KDE Plasma, some applications (notably media players like Strawberry and DAWs like FL Studio) do **not reliably prevent system suspend** while they are active. Conversely, KDE may keep the screen awake during media playback even when the system is idle.

This project provides a **general-purpose smart sleep inhibitor** that:

* Prevents **system suspend** while an application is active
* Still allows the **screen to turn off** when the session is idle or locked
* Supports multiple application behaviors via simple modes:

  * Media players (inhibit only while playing)
  * DAWs / render jobs (always inhibit while running)

The logic is split into:

* A reusable inhibitor script
* Thin per-application wrapper scripts

---

## Files

```
├── smart-inhibitor.sh        # Core logic (reusable)
├── strawberry-smart.sh    # Media player example
└── flstudio-smart.sh      # DAW example
```

---

## Setup

### 1. Install the Scripts

1. Place the scripts somewhere stable (e.g. `~/Scripts/`).
2. Make them executable:

```bash
chmod +x ~/Scripts/smart-inhibitor.sh
chmod +x ~/Scripts/strawberry-smart.sh
chmod +x ~/Scripts/flstudio-smart.sh
```

---

## How It Works

### `smart-inhibitor.sh`

This script manages power behavior using **systemd inhibitors**:

* Blocks **system sleep**
* Does **not** block idle detection
* Forces the screen off when the session is idle

It supports two modes:

| Mode      | Behavior                                                                      |
| --------- | ----------------------------------------------------------------------------- |
| `playing` | Inhibits sleep only while media is actively playing (via MPRIS / `playerctl`) |
| `always`  | Inhibits sleep for the entire lifetime of the target process                  |

---

## Strawberry (Media Player)

### Wrapper Script

`strawberry-wrapper.sh` launches Strawberry and starts the inhibitor in `playing` mode:

```bash
#!/bin/bash

strawberry %U &
APP_PID=$!

~/Scripts/smart-inhibitor.sh "$APP_PID" playing strawberry &

wait "$APP_PID"
```

### Desktop Entry Configuration

1. Copy the system `.desktop` file:

```bash
cp /usr/share/applications/strawberry.desktop ~/.local/share/applications/
```

2. Edit it:

```bash
~/.local/share/applications/strawberry.desktop
```

3. Change the `Exec=` line:

**Original**

```ini
Exec=strawberry %U
```

**Modified**

```ini
Exec=/home/YOURUSER/Scripts/strawberry-smart.sh %U
```

4. Refresh KDE’s application cache:

```bash
kbuildsycoca6
```

Now:

* System suspend is blocked while music is playing
* Screen still turns off when idle or locked
* Inhibitor exits cleanly when Strawberry closes

---

## FL Studio (DAW / Always-On Apps)

DAWs and render jobs should **always prevent sleep** while running.

### Wrapper Script

`flstudio-smart.sh`:

```bash
#!/bin/bash

FL64 &
APP_PID=$!

~/Scripts/smart-inhibitor.sh "$APP_PID" always &

wait "$APP_PID"
```

### Desktop Entry Example

```ini
[Desktop Entry]
Name=FL Studio
Comment=Digital Audio Workstation
Exec=/home/YOURUSER/Scripts/flstudio-smart.sh
Icon=flstudio
Terminal=false
Type=Application
Categories=Audio;Music;AudioVideo;
```

---

## Notes

* Media players often **re-exec or hand off to an existing instance**, so PID monitoring alone is unreliable.
  In `playing` mode, the inhibitor follows the **media player via MPRIS**, not the launcher PID.
* The screen-off logic works on **KDE Plasma Wayland** using `kscreen-doctor`.
* Output names (e.g. `output.eDP-1`) may need adjustment per system.
* This setup intentionally avoids tying inhibitor lifetime to `.desktop` launcher processes.

---

## Future Extensions

The same inhibitor can be extended to:

* MIDI activity detection (DAWs)
* Multiple simultaneous apps
* PipeWire / JACK awareness
* Event-driven DBus monitoring instead of polling
