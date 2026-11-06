#!/usr/bin/env bash
set -euo pipefail

REPO=omashiri
ARCH=x86_64
REMOTE="${REMOTE:?set REMOTE, e.g. pkgdeploy@host:/srv/omashiri-repo/$REPO/os/$ARCH (a local path works too)}"
KEY="${GPG_KEY_ID:?set GPG_KEY_ID}"
OUT="${1:?usage: publish.sh <dir with built packages>}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# 1. fetch the current db state (ignore errors on first run)
rsync -a --include="$REPO.db*" --include="$REPO.files*" --exclude='*' \
  "$REMOTE/" "$work/" || true

# 2. sign the packages
cp "$OUT"/*.pkg.tar.zst "$work/"
for p in "$work"/*.pkg.tar.zst; do
  [[ -f "$p.sig" ]] || gpg --batch --yes --local-user "$KEY" --detach-sign "$p"
done

# 3. update and sign the db
( cd "$work" && repo-add --sign --key "$KEY" --verify "$REPO.db.tar.zst" ./*.pkg.tar.zst )

# 4. upload packages first
rsync -av "$work"/*.pkg.tar.zst "$work"/*.pkg.tar.zst.sig "$REMOTE/"

# 5. then the db files, renamed into place together
rsync -avl --delay-updates \
  "$work/$REPO".db* "$work/$REPO".files* "$REMOTE/"
