FROM archlinux:base-devel

# Enable multilib for lib32-* dependencies (e.g. wineasio-git needs lib32-jack).
RUN sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf

# Update packages.
RUN pacman -Syu --noconfirm

# Install tooling needed before aurutils is installed (curl fetches the
# existing repository database, ninja enables aur-sync --keep-going).
# git, gnupg and jq arrive as dependencies of aurutils.
# mandoc band-aids PKGBUILDs missing it from makedepends (e.g. serd-git's
# meson now requires it at build time). rapidjson likewise for tenacity-git.
RUN pacman -S --needed --noconfirm ccache curl git mandoc ninja pcre rapidjson

# Allow PKGBUILDs to clone git submodules over file:// transport (blocked by
# default since CVE-2022-39253; needed by cardinal-git, bespokesynth-git, dexed-git).
RUN git config --system protocol.file.allow always

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
