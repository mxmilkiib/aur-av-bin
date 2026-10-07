---
title: "AURCI"
---

Use [GitHub Actions] for building and packaging [AUR] packages and deploy them
to [GitHub Releases] so it can be used as repository in [Arch Linux].

[![Build Status]](https://github.com/mxmilkiib/aur-av-bin/actions/workflows/build.yml)

## Use repository

To use as custom repository in [Arch Linux], add to file `/etc/pacman.conf`:

```bash
[{{ site.github.project_title }}]
SigLevel = Optional TrustAll
Server = {{ site.github.owner_url }}/{{ site.github.project_title }}/releases/download/repository
```

Then on the command line:

```bash
# Refresh package database
pacman -Syu

# Show packages in repository
pacman -Sl {{ site.github.project_title }}

# Install a package
pacman -S <package_name>
```

## Custom settings

If you need to customize the build, you can add your own `makepkg.conf`
in the root directory of your repository, the workflow will copy and use it
during the build process.

## Upstream contributions

If you want to contribute back some new feature you need:

- Switch to `master` from your personal repository: `git checkout master && git pull`
- Create a new feature branch: `git checkout -b my-feature`
- Add and commit your changes
- Push on your remote branch and go to the suggested GitHub page to create a
  new pull request.

[Arch Linux]:       https://www.archlinux.org
[AUR]:              https://aur.archlinux.org
[Build Status]:     https://github.com/mxmilkiib/aur-av-bin/actions/workflows/build.yml/badge.svg
[GitHub Actions]:   https://github.com/mxmilkiib/aur-av-bin/actions/workflows/build.yml
[GitHub Releases]:  {{ site.github.owner_url }}/{{ site.github.project_title }}/releases
