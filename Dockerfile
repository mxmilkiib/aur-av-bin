FROM archlinux:base-devel

# Enable multilib for lib32-* dependencies (e.g. wineasio-git needs lib32-jack).
# Append rather than uncomment: the image's pacman.conf may not carry the
# commented block.
RUN grep -qxF '[multilib]' /etc/pacman.conf || \
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf

# Update packages.
RUN pacman -Syu --noconfirm

# Install tooling needed before aurutils is installed (curl fetches the
# existing repository database, ninja enables aur-sync --keep-going).
# git, gnupg and jq arrive as dependencies of aurutils.
# Preinstall deps that PKGBUILDs omit from makedepends so configure-time
# checks still succeed: mandoc (serd-git), rapidjson (tenacity-git),
# qt5-svg (qjackctl-git), glib2-devel's glib-genmarshal (ganv-git),
# lib32-jack2 (wineasio-git; pacman cannot pick the lib32-jack provider
# non-interactively).
RUN pacman -S --needed --noconfirm ccache curl git mandoc ninja pcre rapidjson \
    qt5-svg glib2-devel lib32-jack2

# Allow PKGBUILDs to clone git submodules over file:// transport (blocked by
# default since CVE-2022-39253; needed by cardinal-git, bespokesynth-git,
# dexed-git). makepkg overrides GIT_CONFIG_SYSTEM, so write its config file.
RUN mkdir -p /etc/makepkg.d && \
    git config --file /etc/makepkg.d/gitconfig protocol.file.allow always

# Clear cache.
RUN pacman -Scc --noconfirm

# Create an unprivileged user.
RUN useradd -m -G wheel -s /bin/bash pkguser

# Grant group wheel sudo rights without password.
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

# Set user.
USER pkguser

# Set working dir.
WORKDIR /home/pkguser

# Create dirs.
RUN mkdir src bin
