#!/bin/bash

strawberry %U &
APP_PID=$!

# Start inhibitor in background
/usr/bin/smart-inhibitor.sh "$APP_PID" playing strawberry &

# Wait for Strawberry to exit
wait "$APP_PID"

