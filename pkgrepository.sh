#!/bin/bash

set -ex

# Variables declaration.
declare -r pkgslug="$1"
declare -r pkgtag="$2"
declare -r pkgrepo="${1#*/}"

# Download or create repository database.
cd "bin"
if curl -L -O -O -f "https://github.com/${pkgslug}/releases/download/${pkgtag}/${pkgrepo}.{db,files}.tar.gz"; then
  ln -fs "${pkgrepo}.db.tar.gz" "${pkgrepo}.db"
  ln -fs "${pkgrepo}.files.tar.gz" "${pkgrepo}.files"
else
  rm -f "${pkgrepo}.db.tar.gz" "${pkgrepo}.files.tar.gz"
  repo-add "${pkgrepo}.db.tar.gz"
fi
cd ".."

# Enable multilib repository.
sudo sed -i -e "/\[multilib\]/,/Include/s/^#//" "/etc/pacman.conf"

# Add configuration for repository.
sudo tee -a "/etc/pacman.d/${pkgrepo}" << EOF
[options]
CacheDir = /var/cache/pacman/pkg
CacheDir = $(pwd)/bin
CleanMethod = KeepCurrent

[${pkgrepo}]
SigLevel = Optional TrustAll
Server = file://$(pwd)/bin
Server = https://github.com/${pkgslug}/releases/download/${pkgtag}
EOF

# Include the repository. aurutils itself is in [extra].
sudo tee -a "/etc/pacman.conf" << EOF

Include = /etc/pacman.d/${pkgrepo}
EOF

# Sync repositories and install aurutils.
sudo pacman -Syu --needed --noconfirm aurutils

{ set +ex; } 2>/dev/null
