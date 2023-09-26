#!/usr/bin/env bash
set -e

PIDFILE="anvil.pid"

# Read the stored process ID and remove the file
if [ -f $PIDFILE ]; then
    ANVIL_PID=$(cat $PIDFILE)
    rm -f $PIDFILE

    # Stop the process
    kill -9 $ANVIL_PID
    echo -e "\nanvil process has been stopped.\n"

else
    echo -e "\nNo anvil process found.\n"
fi
