#!/bin/bash
set -e

export WINEPREFIX=/root/.mt5
export DISPLAY=:1

# Check if MT5 is already installed
if [ -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then
    echo "MT5 is already installed, launching MT5..."
    # Fix Wine registry issues
    wineserver -w
    wine reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    wine "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" /portable
    exit 0
fi

echo "MT5 not found, proceeding with installation..."

# MetaTrader download url
URL="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
# WebView2 Runtime download url
URL_WEBVIEW="https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/c1336fd6-a2eb-4669-9b03-949fc70ace0e/MicrosoftEdgeWebview2Setup.exe"
# Wine version to install: stable or devel
WINE_VERSION="stable"

rm -f /etc/apt/sources.list.d/winehq*

dpkg --add-architecture i386
mkdir -pm755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

OS_VER=$(lsb_release -r |cut -f2 |cut -d "." -f1)

wget -nc https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
mv winehq-bookworm.sources /etc/apt/sources.list.d/

apt update
apt upgrade -y
apt install --install-recommends -y winehq-$WINE_VERSION wget

wget -O /tmp/mt5setup.exe $URL
wget -O /tmp/webview2setup.exe $URL_WEBVIEW

winecfg -v=win10
wine /tmp/webview2setup.exe /silent /install

# Run MT5 installer
wine /tmp/mt5setup.exe &



# Wait until terminal64.exe appears
while [ ! -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; do
    echo "Waiting for MetaTrader 5 to finish installing..."
    sleep 3
done

echo "MT5 installed! Killing auto-launched MT5..."
# Kill any auto-launched MT5 instances
sleep 10
pkill -f terminal64.exe

sleep 5
echo "Launching in portable mode..."
# Launch it in portable mode to generate MQL5/Experts folders
wine "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" /portable &

# Wait for MQL5/Experts folder to be created
while [ ! -d "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/MQL5/Experts" ]; do
    echo "Waiting for Experts folder..."
    sleep 2
done

sleep 2
echo "Copying EA..."
mv /SocketBridgeEA.ex5 "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/MQL5/Experts/SocketBridgeEA.ex5"

