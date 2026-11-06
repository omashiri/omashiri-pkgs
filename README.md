# omashiri-pkgs

Package recipes for the omashiri headless server image. Derived from
[omacom/omarchy-pkgs](https://github.com/omacom/omarchy-pkgs), cut down to the
kernel, boot, snapper and server packages.

Packages are built in CI and served at `https://pkg.omashiri.com/x86_64/`.

## Use the repo

Add to `/etc/pacman.conf`:

```
[omashiri]
SigLevel = Required
Server = https://pkg.omashiri.com/$repo/os/$arch
```

The public key must be trusted first (`pacman-key`), eventually via an
`omashiri-keyring` package.

## Packages

`pkgbuilds/<name>/` holds a `PKGBUILD` and `.omarchy/package.json` per package.
`omashiri-server` is the meta package the installer pulls in; the other
`omashiri-*` packages are ours, and the rest are imported from Omarchy.

Add one with `bin/add-package <name> --local --scaffold`. Build locally with
`bin/build --package <name>` (Docker or Podman required).

Checks: `tests/*.sh`, also run by `.github/workflows/test.yml` on pull requests.

`omashiri-settings` installs the Omashiri login banner and an interactive profile hook. It shows host, kernel, uptime, resource, GPU (when available), and failed-service information. Create `~/.hushlogin` to disable it. Noninteractive SSH commands and file transfers remain silent; the packaged static `/etc/motd` is empty to avoid a second banner.

## Publishing

`.github/workflows/publish-server.yml` runs on pushes to `main` that touch
`pkgbuilds/` or `scripts/`, on the runner labelled `docker`, inside an
`archlinux` container. It builds every x86_64 or `any` package and calls
`scripts/publish.sh`, which signs the packages, updates and signs the db, and
uploads packages before the db.

Repo secrets: `REMOTE` (the server's IP or hostname; the workflow uploads to
`pkgdeploy@<REMOTE>:/srv/omashiri-repo/omashiri/os/x86_64`), `GPG_SIGNING_KEY` (armored private key), `GPG_KEY_ID`,
`DEPLOY_SSH_KEY` (its public half in `pkgdeploy`'s `authorized_keys`).

Serve `/srv/omashiri-repo` as `pkg.omashiri.com` with any static file server,
for example Caddy `file_server`.
