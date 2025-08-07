#!/bin/bash

# Run the original CMD of the base image
/startup.sh &

# Wait a few seconds for the desktop to boot
sleep 10

# Now run your MT5 setup
/mt5-mt5debian.sh &

# keep container alive
wait
