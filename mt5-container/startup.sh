#!/bin/bash

export USER=root

# Clean up any leftover VNC lock files and processes
rm -f /tmp/.X*-lock
rm -rf /tmp/.X11-unix/X*
pkill -f vnc || true

# Set defaults for environment variables if not provided
VNC_RESOLUTION=${VNC_RESOLUTION:-1600x900}
VNC_DEPTH=${VNC_DEPTH:-24}

# Create VNC password file using the environment variable
mkdir -p /root/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Start the D-Bus daemon
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval `dbus-launch --sh-syntax`
fi

# Start the VNC server on display :1 with the specified resolution and depth
tightvncserver :1 -geometry $VNC_RESOLUTION -depth $VNC_DEPTH

# Wait briefly to ensure the VNC server is ready
sleep 2

# Start noVNC (via websockify) to bridge port 6080 (for browser access) to VNC port 5901
websockify --web=/usr/share/novnc 6080 localhost:5901