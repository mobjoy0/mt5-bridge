# Debian XFCE with VNC, NoVNC and MetaTrader 5

This Docker image provides a Debian environment with XFCE desktop, accessible via VNC through a browser using NoVNC, with MetaTrader 5 pre-configured to run through Wine.

## Overview

This Docker image sets up:
- Debian 12 based environment
- XFCE desktop environment
- TightVNC server for remote desktop access
- NoVNC for browser-based VNC access
- Wine configured for running Windows applications
- MetaTrader 5 ready to install and run
- Commonly used utilities (Firefox, Git, etc.)

**Credits:** This image is based on the excellent VNC/NoVNC Docker setup by [MrDKGE](https://github.com/MrDKGE/Debian-XFCE-VNC). Special thanks for the original Debian XFCE VNC implementation.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed on your system

### Setup and Run

1. Clone this repository:
```sh
git clone https://github.com/mobjoy0/MetaTrader5-vnc-docker.git
cd MetaTrader-vnc-docker
```

2. Build and start the container:
```sh
docker compose up -d
```

3. Access the desktop environment:
   - Open your web browser and navigate to: `http://localhost:6080`
   - Enter the VNC password (default: "yourpassword")

### First Time Setup (Important!)

**Please wait 2-5 minutes after the container starts** - this allows all services to fully initialize.

When you first access the desktop:

1. **Mono Installation**: You will see a Mono installer dialog appear automatically. Click **"Install"** to proceed with the Mono installation (required for Wine).

2. **MetaTrader 5 Installation**: After Mono installation completes, the MetaTrader 5 installer will launch automatically. Follow the installation wizard to complete the MT5 setup.

3. Once both installations are complete, MetaTrade5 will launch automatically.

## Configuration

You can customize the environment through the following variables in docker-compose.yml:
- `VNC_PASSWORD`: Set your preferred VNC password
- `VNC_RESOLUTION`: Change the screen resolution (default: 1600x900)
- `VNC_DEPTH`: Color depth (default: 24)

## Data Persistence

The container mounts a data directory to `/opt/data` inside the container for persistent storage.

## Security Considerations

- This image is primarily intended for development or internal use
- Change the default VNC password before deploying to production
- Consider using additional security measures when exposing publicly