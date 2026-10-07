#!/bin/bash

set -ex

# Variables declaration.
declare -r pkgslug="$1"
declare -r pkgtag="$2"
declare -r pkgrepo="${1#*/}"

# Download or create repository database.
cd "bin"
if curl -L -O -f "https://github.com/${pkgslug}/releases/download/${pkgtag}/${pkgrepo}.db.tar.gz"; then
  curl -L -O -f "https://github.com/${pkgslug}/releases/download/${pkgtag}/${pkgrepo}.files.tar.gz" || true
  ln -fs "${pkgrepo}.db.tar.gz" "${pkgrepo}.db"
  if [ -f "${pkgrepo}.files.tar.gz" ]; then
    ln -fs "${pkgrepo}.files.tar.gz" "${pkgrepo}.files"
  fi
else
  rm -f "${pkgrepo}.db.tar.gz" "${pkgrepo}.files.tar.gz" "${pkgrepo}.db" "${pkgrepo}.files"
  repo-add "${pkgrepo}.db.tar.gz"
fi
cd ".."

# Enable multilib repository.
sudo sed -i -e "/\[multilib\]/,/Include/s/^#//" "/etc/pacman.conf"

# Add configuration for repository. DisableSandbox lets the sandboxed
# pacman 7 downloader reach the file:// server inside ~pkguser (which is
# created 0700 and outside the sandbox's allowed paths).
sudo tee -a "/etc/pacman.d/${pkgrepo}" << EOF
[options]
CacheDir = /var/cache/pacman/pkg
CacheDir = $(pwd)/bin
CleanMethod = KeepCurrent
DisableSandbox

[${pkgrepo}]
SigLevel = Optional TrustAll
Server = file://$(pwd)/bin
Server = https://github.com/${pkgslug}/releases/download/${pkgtag}
EOF

# Include the repository.
sudo tee -a "/etc/pacman.conf" << EOF

Include = /etc/pacman.d/${pkgrepo}
EOF

# Sync repositories and update packages.
sudo pacman -Syu --noconfirm

# Bootstrap aurutils from the AUR (it is not in the official repositories).
git clone https://aur.archlinux.org/aurutils.git "${HOME}/src/aurutils"
(cd "${HOME}/src/aurutils" && makepkg -sirc --noconfirm)

{ set +ex; } 2>/dev/null
