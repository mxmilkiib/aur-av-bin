#!/bin/bash

set -ex

# Environment variables.
makepkg_conf="/home/pkguser/.makepkg.conf"
if [ ! -f ${makepkg_conf} ] || ! $(grep -Fxq "PACKAGER" ${makepkg_conf}) ; then
  export PACKAGER="${1/\// } <${2}@github.actions>"
fi
export AURDEST="$(pwd)/src"
export AUR_SYNC_USE_NINJA=1

# Variables declaration.
declare -r pkgrepo="${1#*/}"
declare -a pkglist=()
declare -a pkgkeys=()
declare -a pkgdeps=()

# Remove comments or blank lines.
for pkgfile in "pkglist" "pkgkeys"; do
  sed -i -e "/\s*#.*/s/\s*#.*//" -e "/^\s*$/d" $pkgfile
done

# Load files.
mapfile -t pkglist < "pkglist"
mapfile -t pkgkeys < "pkgkeys"

# Create package list with dependencies. aur-depends prints
# "pkgname<TAB>depends" pairs; flatten both columns to a plain list.
if (( ${#pkglist[@]} )); then
  mapfile pkgdeps < <(aur depends -n "${pkglist[@]}" | tr '\t' '\n' | sort -u)
fi
pkgdeps+=("${pkglist[@]}")

# Remove packages from repository.
cd "bin"
while read -r pkgpackage; do
  repo-remove "${pkgrepo}.db.tar.gz" $pkgpackage
done < <(comm -23 <(pacman -Slq $pkgrepo | sort) <(printf "%s\n" "${pkgdeps[@]}" | sort -u))
cd ".."

# Get package gpg keys.
for pkgkey in ${pkgkeys[@]}; do
  gpg --recv-keys --keyserver "hkps://keyserver.ubuntu.com" $pkgkey
done

# Build outdated packages. --nover-argv always rebuilds command-line targets
# (AUR RPC versions for -git packages are stale snapshots, so version checks
# would skip them forever). --keep-going=0 lets independent packages build
# even if others fail.
if (( ${#pkglist[@]} )); then
  aur sync -d $pkgrepo --root "${HOME}/bin" -n --noview --nover-argv --keep-going=0 ${pkglist[@]}
fi

# Workaround fo GH releases because colon in names not permitted
if [[ ${DEPLOY_CUSTOM} != 1 ]]; then
  cd "bin"
  for package in *.pkg.tar.*; do
    if [[ ${package} == *':'* ]]; then
      echo "renaming ${package} and add it back to db..."
      newname=${package/:/.}
      mv -- ${package} ${newname}
      repo-add "${pkgrepo}.db.tar.gz" ${newname}
    fi
  done
  cd ..
fi

{ set +ex; } 2>/dev/null
