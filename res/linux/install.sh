#!/bin/bash
cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this install script with elevated permissions."
    exit 1
fi

install -Dm755 steam-artwork-manager -t /usr/local/bin
chmod +x /usr/local/bin/steam-artwork-manager
desktop-file-install com.steamgriddb.steam-artwork-manager.desktop --delete-original --rebuild-mime-info-cache

su - $SUDO_USER -c "xdg-mime default com.steamgriddb.steam-artwork-manager.desktop x-scheme-handler/sgdb"
echo "Installation complete! You may delete this install script."
exit 0
