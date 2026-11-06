# omashiri-pkgs

Package recipes for the omashiri headless server image. Derived from
[omacom/omarchy-pkgs](https://github.com/omacom/omarchy-pkgs), cut down to the
kernel, boot, snapper and server packages.

Packages are built in CI and served at `https://pkg.omashiri.com/x86_64/`.

## Use the repo

Add to `/etc/pacman.conf`:

```
[omashiri]
SigLevel = Optional TrustAll
Server = https://pkg.omashiri.com/$arch
```

Use `SigLevel = Required` once `GPG_PRIVATE_KEY` is set and the public key ships
in an `omashiri-keyring` package.

## Packages

`pkgbuilds/<name>/` holds a `PKGBUILD` and `.omarchy/package.json` per package.
`omashiri-server` is the meta package the installer pulls in; the other
`omashiri-*` packages are ours, and the rest are imported from Omarchy.

Add one with `bin/add-package <name> --local --scaffold`. Build locally with
`bin/build --package <name>` (Docker or Podman required).

Checks: `tests/*.sh`, also run by `.github/workflows/test.yml` on pull requests.

## Publishing

`.github/workflows/publish-server.yml` runs on pushes to `main` that touch
`pkgbuilds/`. It builds every x86_64 or `any` package, signs if `GPG_PRIVATE_KEY`
is set, runs `repo-add`, and rsyncs to the server.

Server: a `pkg` user owning `/srv/pkg/x86_64`, and a Caddy site

```
pkg.omashiri.com {
    root * /srv/pkg
    file_server browse
}
```

Repo secrets: `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS` (`ssh-keyscan <host>`),
`DEPLOY_TARGET` (`pkg@<host>:/srv/pkg/x86_64`), optional `GPG_PRIVATE_KEY`.
