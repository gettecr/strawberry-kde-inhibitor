## Strawberry-KDE-Inhibitor

Using Manjaro + KDE Plasma the Strawberry music app does not prevent the laptop from suspending. This is a simple Bash script to prevent the system from suspending while the Strawberry Music Player is active, ensuring music playback is continuous. It simultaneously allows the screen to turn off by overriding the automatic screen-on behavior that is common when media is playing.

**NOTE**: This may become obsolete if KDE detects that Strawberry is playing and does not suspend.

The script dynamically sets the screen-off timer:
- **Locked Screen:** The screen turns off after **60 seconds**.
- **Unlocked Screen:** The screen turns off based on your current **KDE Energy Saving Settings**.

---

## Setup and Desktop Entry Configuration

### 1. Save the Script

1.  Place the script in a directory in your `$PATH` (e.g., `~/bin/` or `/usr/local/bin/`).
2.  Make it executable:
    ```bash
    chmod +x /path/to/strawberry-smart.sh
    ```

### 2. Modify the Strawberry Desktop Entry

To launch Strawberry with the smart inhibitor script instead of launching the player directly, you need to edit its `.desktop` file.

1.  **Locate the `.desktop` file:**
    The file is usually located in `/usr/share/applications/strawberry.desktop`. To edit it for your user only, copy it to your local applications folder:
    ```bash
    cp /usr/share/applications/strawberry.desktop ~/.local/share/applications/
    ```

2.  **Edit the file:** Open the copied file (`~/.local/share/applications/strawberry.desktop`) with a text editor.

3.  **Change the `Exec=` line:** Find the line starting with `Exec=` and change the command from the default:

    **Original:**
    ```ini
    Exec=strawberry %U
    ```

    **Modified:**
    (Replace `/path/to/` with the actual path where you saved the script.)
    ```ini
    Exec=/path/to/strawberry-smart.sh %U
    ```

4.  **Save the file.**

Now, when you launch Strawberry from the application launcher or a panel/dock icon, it will execute your script, which in turn manages the power settings and launches the player. When you close Strawberry, the script will automatically terminate the background power-management loop.
