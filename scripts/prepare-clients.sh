#!/usr/bin/env bash
set -euo pipefail

ref="${1:?Usage: prepare-clients.sh <tag-or-commit-sha>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
destination="$root/work/clients"

rm -rf "$destination"
mkdir -p "$(dirname "$destination")"
git init "$destination"
git -C "$destination" remote add origin https://github.com/bitwarden/clients.git
git -C "$destination" fetch --depth 1 origin "$ref"
git -C "$destination" checkout --detach FETCH_HEAD

# Remove all first-party proprietary client source before dependency resolution/build.
rm -rf "$destination/bitwarden_license"

# The upstream root manifest declares this commercial SDK even though OSS targets
# don't consume it. Remove it from the temporary checkout before npm regenerates
# the lockfile, so neither installation nor builds depend on the commercial package.
node - "$destination/package.json" <<'NODE'
const fs = require('node:fs');
const path = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
delete pkg.dependencies?.['@bitwarden/commercial-sdk-internal'];
fs.writeFileSync(path, `${JSON.stringify(pkg, null, 2)}\n`);
NODE

commit="$(git -C "$destination" rev-parse HEAD)"
echo "Prepared open-source-only checkout at $destination (requested ref: $ref, commit: $commit)"
