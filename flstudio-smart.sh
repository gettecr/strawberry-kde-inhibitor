#!/bin/bash

# Launch FL Studio
FL64 &
APP_PID=$!

# Always inhibit sleep while FL Studio is running
~/Scripts/smart-inhibitor.sh "$APP_PID" always &

# Wait for FL Studio to exit
wait "$APP_PID"

