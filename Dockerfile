FROM archlinux:base-devel

# Update packages.
RUN pacman -Syu --noconfirm

# Install tooling needed before aurutils is installed (curl fetches the
# existing repository database, ninja enables aur-sync --keep-going).
# git, gnupg and jq arrive as dependencies of aurutils.
# mandoc band-aids PKGBUILDs missing it from makedepends (e.g. serd-git's
# meson now requires it at build time).
RUN pacman -S --needed --noconfirm ccache curl git mandoc ninja pcre

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
