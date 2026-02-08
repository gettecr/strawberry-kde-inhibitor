#!/bin/bash

PLAYER="strawberry"
SESSION_ID="${XDG_SESSION_ID}"

# Fallback if XDG_SESSION_ID is missing
if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID=$(loginctl list-sessions --no-legend | awk 'NR==1 {print $1}')
fi

# Pick qdbus binary
QDBUS=$(command -v qdbus6 || command -v qdbus)

# List your outputs here
OUTPUTS=(
  "output.eDP-1"
  # "output.DP-1"
)

screen_off() {
  for o in "${OUTPUTS[@]}"; do
    kscreen-doctor "$o.disable" &>/dev/null
  done
}

is_idle() {
  loginctl show-session "$SESSION_ID" -p IdleHint --value | grep -q yes
}

is_locked() {
  "$QDBUS" org.freedesktop.ScreenSaver \
    /org/freedesktop/ScreenSaver \
    org.freedesktop.ScreenSaver.GetActive 2>/dev/null | grep -q true
}

echo "Strawberry Smart Inhibitor started."

while true; do
  STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)

  if [[ "$STATUS" == "Playing" ]]; then
    # Start inhibitor in background
    systemd-inhibit \
      --who="Strawberry Smart" \
      --why="Music Playing" \
      --what=sleep \
      sleep infinity &
    INHIBIT_PID=$!

    while playerctl -p "$PLAYER" status 2>/dev/null | grep -q Playing; do
      if is_idle || is_locked; then
        screen_off
      fi
      sleep 5
    done

    kill "$INHIBIT_PID" 2>/dev/null
  fi

  sleep 3
done &
LOOP_PID=$!

strawberry %U

kill "$LOOP_PID"
