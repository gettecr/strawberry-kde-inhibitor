#!/bin/bash

# USAGE:
#   smart-inhibitor.sh <PID_TO_WATCH> <MODE> [PLAYER_NAME]
#
# MODES:
#   always   -> inhibit as long as PID exists (DAWs, render jobs)
#   playing  -> inhibit only while media is Playing (MPRIS-based)
#
# NOTES:
#   - In "playing" mode, PID is ONLY used as a fallback
#   - Player presence is determined via playerctl (NOT the launcher PID)

TARGET_PID="$1"
MODE="$2"
PLAYER_NAME="$3"

INHIBIT_PID=""

# ---- CONFIG ----

OUTPUTS=(
  "output.eDP-1"
  # "output.DP-1"
)

CHECK_INTERVAL=5

# ---- DEPENDENCIES ----

QDBUS=$(command -v qdbus6 || command -v qdbus)

# ---- CLEANUP ----

cleanup() {
  if [[ -n "$INHIBIT_PID" ]]; then
    kill "$INHIBIT_PID" 2>/dev/null
  fi
  exit 0
}
trap cleanup EXIT INT TERM

# ---- HELPERS ----

screen_off() {
  for o in "${OUTPUTS[@]}"; do
    kscreen-doctor "$o.disable" &>/dev/null
  done
}

get_session_id() {
  if [[ -n "$XDG_SESSION_ID" ]]; then
    echo "$XDG_SESSION_ID"
  else
    loginctl list-sessions --no-legend | awk 'NR==1 {print $1}'
  fi
}

is_idle() {
  loginctl show-session "$(get_session_id)" \
    -p IdleHint --value | grep -q yes
}

is_locked() {
  "$QDBUS" org.freedesktop.ScreenSaver \
    /org/freedesktop/ScreenSaver \
    org.freedesktop.ScreenSaver.GetActive 2>/dev/null | grep -q true
}

start_inhibit() {
  if [[ -z "$INHIBIT_PID" ]] || ! kill -0 "$INHIBIT_PID" 2>/dev/null; then
    systemd-inhibit \
      --who="Smart Inhibitor" \
      --why="Application activity detected" \
      --what=sleep \
      sleep infinity &
    INHIBIT_PID=$!
  fi
}

stop_inhibit() {
  if [[ -n "$INHIBIT_PID" ]]; then
    kill "$INHIBIT_PID" 2>/dev/null
    INHIBIT_PID=""
  fi
}

player_alive() {
  if [[ -n "$PLAYER_NAME" ]]; then
    playerctl -p "$PLAYER_NAME" status &>/dev/null
  else
    playerctl status &>/dev/null
  fi
}

player_playing() {
  if [[ -n "$PLAYER_NAME" ]]; then
    [[ "$(playerctl -p "$PLAYER_NAME" status 2>/dev/null)" == "Playing" ]]
  else
    [[ "$(playerctl status 2>/dev/null)" == "Playing" ]]
  fi
}

# ---- MAIN LOOP ----

echo "Smart Inhibitor started | Mode=$MODE | Player=${PLAYER_NAME:-any}"

while true; do
  # ---- EXIT CONDITIONS ----
  if [[ "$MODE" == "playing" ]]; then
    player_alive || break
  else
    kill -0 "$TARGET_PID" 2>/dev/null || break
  fi

  SHOULD_INHIBIT=false

  if [[ "$MODE" == "always" ]]; then
    SHOULD_INHIBIT=true
  elif [[ "$MODE" == "playing" ]]; then
    player_playing && SHOULD_INHIBIT=true
  fi

  if $SHOULD_INHIBIT; then
    start_inhibit

    if is_idle; then
      screen_off
    fi
  else
    stop_inhibit
  fi

  sleep "$CHECK_INTERVAL"
done

