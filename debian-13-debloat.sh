#!/bin/bash

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root. Please use sudo." >&2
   exit 1
fi

echo "Starting Debian 13 KDE debloat process..."

PACKAGES=(
    goldendict-ng
    juk
    dragonplayer
    anthy-common
    uim
    mozc-server
    mozc-data
    kontrast
    ibus
    xiterm+thai
    xterm
    kmouth
    konqueror
    akregator
    "fonts-lohit-*"
    "fcitx*"
    "akonadi*"
    "kdepim*"
)

echo "Purging specified packages..."

if ! apt-get purge -y "${PACKAGES[@]}"; then
    echo "Warning: apt-get encountered an issue (likely a package was already removed or a wildcard found no matches). Continuing..."
fi

echo "Running autoremove to clean up orphaned dependencies..."
if ! apt-get autoremove --purge -y; then
    echo "Error: Failed to run autoremove." >&2
    exit 1
fi

echo "Checking for residual config files from previously deleted packages..."
# dpkg -l lists packages, awk extracts the names of packages marked 'rc' (removed but config remains)
RESIDUALS=$(dpkg -l | awk '/^rc/ { print $2 }')

if [[ -n "$RESIDUALS" ]]; then
    echo "Purging residual configurations..."
    # We do NOT quote $RESIDUALS here so it expands into separate package names for apt-get
    if ! apt-get purge -y $RESIDUALS; then
        echo "Warning: Failed to purge some residual configuration files. Continuing..."
    fi
else
    echo "No residual configuration files found."
fi

echo "Cleaning up APT cache..."
apt-get clean

if command -v flatpak &> /dev/null; then
    echo "Cleaning up unused Flatpak runtimes and dependencies..."
    if ! flatpak uninstall --unused -y; then
        echo "Warning: Flatpak cleanup encountered an issue. Continuing..."
    fi
fi

echo "Debloat complete! A reboot is recommended to ensure all background services are fully terminated."
