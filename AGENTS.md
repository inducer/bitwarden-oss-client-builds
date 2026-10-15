# Agent context

## Repository purpose

This repository builds a limited set of Bitwarden open-source client artifacts from upstream source and publishes them as assets on GitHub prereleases (see README.md). It is build automation, not a fork of either upstream repository.

The main workflow is `.github/workflows/build.yml`; see `README.md` for user-facing usage and licensing notes.

## Upstream source locations

You are likely to be able to find upstream sources in

- $HOME/pack/bitwarden-clients
- $HOME/pack/bitwarden-android

These may be out of date, please check and remind the user to pull if more than a few days out of date.

## Upstream source pins

Default upstream revisions are in `upstream-versions.json`. The `tag` records release identity; `commit` is the SHA actually checked out. Keep them aligned when updating pins, and prefer the SHA for reproducible builds.

Workflow dispatch inputs can override these refs for testing. Without overrides, scheduled and push builds use the checked-in pins, not a moving branch. When changing default pins, verify the release tag and commit relationship upstream, review source/license changes, then update `upstream-versions.json` and the README's version table together.

## Workflow structure

- `browser` builds both browser targets from a prepared clients checkout.
- `desktop` independently prepares the same pinned clients revision and builds the Debian package.
- `android` checks out the separately pinned Android repository and builds `:app:assembleFdroidRelease`.
- `publish` waits for all three jobs, downloads their workflow artifacts, writes `SOURCE-REFS.txt`, and publishes the release.
- A workflow-level concurrency group serializes complete runs. Keep this in mind when changing triggers or job dependencies.

Each job checks out this repository first because it uses `scripts/prepare-clients.sh` or the checked-in pin file. Independent build jobs intentionally repeat source setup and dependency installation so they can run concurrently and fail independently. Do not combine their outputs or make the publish job run before all required artifacts exist.

## Open-source filtering and licensing

For `bitwarden/clients`, `scripts/prepare-clients.sh` checks out the requested revision, deletes the entire `bitwarden_license/` subtree before dependency installation/build, and removes the root `@bitwarden/commercial-sdk-internal` dependency from the temporary package manifest. `npm install --package-lock-only` then prunes the temporary lockfile before `npm ci`. Preserve this ordering and do not modify the user's upstream checkout; preparation is done in the runner's `work/clients` directory.

The Android build must use the `fdroid` flavor, not `standard`. Upstream scopes Google Billing, Firebase, ML Kit, and Play Review dependencies to `standard`; F-Droid also excludes the documented non-FOSS Play Services backend. Review upstream flavor definitions when changing Android build tasks.

This configuration is not a complete third-party dependency license audit and is not legal advice. Re-check upstream license notices, packaging, and dependencies when changing source revisions or build targets.

## Android package access

The Android build may need the Bitwarden SDK Maven package in GitHub Packages. The workflow passes `ANDROID_SDK_TOKEN` when configured, otherwise `GITHUB_TOKEN`. If CI cannot resolve the package, check token/package access first. The README documents the required token setup.

## Editing and validation guidance

- Keep changes scoped to this build system; do not edit upstream checkout contents here except via the preparation/build scripts.
- If adding a new output, ensure its job uploads it as a workflow artifact and that `publish` waits on the job and includes the artifact. Update `README.md` accordingly.
- Preserve least-privilege permissions: build jobs need read access; only `publish` needs `contents: write`.
- Validate workflow YAML, `upstream-versions.json`, and shell scripts after edits. A full build requires network access and the hosted GitHub Actions environment; local syntax checks do not demonstrate that upstream builds succeed.
- Do not claim build success without running the workflow/build or observing successful CI output.
