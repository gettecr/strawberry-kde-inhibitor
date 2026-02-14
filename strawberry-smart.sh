#!/bin/bash

strawberry %U &
APP_PID=$!

sleep 2
# Start inhibitor in background
~/Scripts/smart-inhibitor.sh "$APP_PID" playing strawberry &

# Wait for Strawberry to exit
wait "$APP_PID"

