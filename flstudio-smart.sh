#!/bin/bash


# Launch FL Studio
FL_EXE="C:\\Program Files\\Image-Line\\FL Studio 2025\\FL64.exe"
WINE_PREFIX="/home/<your-user>/.wine"

env WINEPREFIX="$WINE_PREFIX" wine "$FL_EXE" &
APP_PID=$!

echo "FL Studio found at PID: $APP_PID"

# Launch the inhibitor
~/Scripts/smart-inhibitor.sh "$APP_PID" always &

wait "$APP_PID"

echo "FL Studio closed."

