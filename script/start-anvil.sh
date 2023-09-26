#!/usr/bin/env bash
set -e

PIDFILE="anvil.pid"
LOCALHOST="http://localhost:8545"

# Check if PID file exists
if [ -f $PIDFILE ]; then
  # Read PID from file
  ANVIL_PID=$(cat $PIDFILE)

  # Check if process is running
  if ps -p $ANVIL_PID > /dev/null; then
    echo -e "\nanvil is already running with PID $ANVIL_PID.\n"
    echo -e "Listening on $LOCALHOST.\n"
    exit 0
  else
    echo -e "\n$PIDFILE file exists but process is not running. Starting anvil..."
    rm -f $PIDFILE
  fi
fi

# Start anvil in the background
anvil --silent &

# Save PID to file
PID=$!
echo $PID > $PIDFILE

echo -e "\nanvil started with PID $PID.\n"
echo -e "Listening on $LOCALHOST.\n"

