#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_UNLOCKED_TIMEOUT=300  # Default to 5 minutes if config is not found
LOCKED_TIMEOUT=60             # Screen turns off after 60 seconds when locked
# ---------------------

get_unlocked_timeout() {
  # Read the configured 'Turn off screen' time from powerdevilrc (in seconds)
  if command -v kreadconfig6 &> /dev/null; then
    CMD="kreadconfig6"
  else
    CMD="kreadconfig5"
  fi

  TIMEOUT=$($CMD --file powerdevilrc --group AC --group Display --key TurnOffDisplayIdleTimeout 2>/dev/null)

  if [ -z "$TIMEOUT" ]; then
    echo "$DEFAULT_UNLOCKED_TIMEOUT"
  else
    echo "$TIMEOUT"
  fi
}

is_screen_locked() {
  # Ask the KScreenLocker daemon if the screen is currently locked.
  # Returns 1 (true) or 0 (false)
  LOCKED=$(qdbus org.kde.ScreenLocker /ScreenLocker org.kde.ScreenLocker.isLocked 2>/dev/null)

  # qdbus output is "true" or "false" (or empty if the daemon is missing)
  if [ "$LOCKED" = "true" ]; then
    return 0  # Bash function return code for SUCCESS/TRUE
  else
    return 1  # Bash function return code for FAILURE/FALSE
  fi
}

# Start the Monitor Loop
(
  while true; do
    STATUS=$(playerctl -p strawberry status 2>/dev/null)

    if [ "$STATUS" = "Playing" ]; then

      # DETERMINE THE SCREEN-OFF LIMIT
      MS_LIMIT=0
      if is_screen_locked; then
        # Use the fast timeout (60 seconds)
        MS_LIMIT=$((LOCKED_TIMEOUT * 1000))

      else
        # Use the slow, user-configured timeout (e.g., 5 minutes)
        SEC_LIMIT=$(get_unlocked_timeout)
        MS_LIMIT=$((SEC_LIMIT * 1000))
      fi

      # CHECK IDLE TIME
      CURRENT_IDLE=$(qdbus org.kde.Idletime /IdleTime org.kde.IdleTime.get 2>/dev/null)
      if [ -z "$CURRENT_IDLE" ]; then CURRENT_IDLE=0; fi

      # FORCE SCREEN OFF
      if [ "$CURRENT_IDLE" -ge "$MS_LIMIT" ]; then
         qdbus org.kde.kglobalaccel /component/org_kde_powerdevil invokeShortcut "Turn Off Screen"
      fi

      # BLOCK SLEEP (Keep CPU Awake)
      systemd-inhibit --who="Strawberry Smart" --why="Music Playing" --what=sleep sleep 15

    else
      # MUSIC PAUSED - Let system sleep normally
      sleep 10
    fi
  done
) &

INHIBITOR_PID=$!
echo "Smart Strawberry started."
echo " - Locked Time: ${LOCKED_TIMEOUT}s | Unlocked Time: Configured/Default"

# Start Strawberry
strawberry %U

# Cleanup
kill $INHIBITOR_PID
