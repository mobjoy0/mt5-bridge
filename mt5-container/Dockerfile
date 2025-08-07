FROM debian:12

# Prevent interactive prompts during package installation and set default environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# Update and install necessary packages (excluding xfce4-power-manager)
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xorg \
    tightvncserver \
    novnc \
    websockify \
    dbus-x11 \
    wget \
    curl \
    unzip \
    && apt-get remove -y xfce4-power-manager \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the xstartup script to launch XFCE immediately at VNC session start
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\n\
xrdb $HOME/.Xresources\n\
startxfce4 &' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# Copy the startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

COPY mt5-mt5debian.sh /mt5-mt5debian.sh
RUN chmod +x /mt5-mt5debian.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY SocketBridgeEA.ex5 /SocketBridgeEA.ex5

# Expose the noVNC port
EXPOSE 6080

# Set the startup script as the default command
CMD ["/entrypoint.sh"]