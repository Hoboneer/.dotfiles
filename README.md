# Personal dotfiles

(This is to remind myself mostly)

## Prerequisites

- GNU stow

## Install

From the root directory of this repo do:

```sh
stow <package>  # -S, --stow (default)
```

where package is a top-level directory.

`stow` will then add symlinks where necessary.

## Uninstall

From the root directory of this repo do:

```sh
stow -D <package>  # --delete
```

where package is a top-level directory.

`stow` will then remove the installed symlinks.

## Reinstall (after making changes)

From the root directory of this repo do:

```sh
stow -R <package>  # --restow
```
