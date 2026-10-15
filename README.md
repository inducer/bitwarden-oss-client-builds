# Bitwarden open-source client builds

This repository contains a GitHub Actions workflow that checks out [`bitwarden/clients`](https://github.com/bitwarden/clients), removes its `bitwarden_license/` subtree, and builds open-source deliverables. It does not modify or redistribute the upstream checkout itself. Each successful run publishes the build files as assets on a prerelease GitHub Release in this repository.

## Current targets

| Target | Status | Build approach |
| --- | --- | --- |
| Linux x86_64 `.deb` | Configured | Desktop native module build, upstream OSS webpack build, then electron-builder's Debian target |
| Firefox extension | Configured | `build:prod:firefox` upstream workspace script |
| Chromium extension | Configured | `build:prod:chrome` upstream workspace script |
| Android | Configured | Checks out `bitwarden/android` and builds the `fdroid` release flavor APK (`:app:assembleFdroidRelease`), which excludes standard-flavor Google Play/Firebase/Billing integrations. |

Trigger a build with **Actions → Build open-source Bitwarden clients → Run workflow**. Leave `clients_ref` and `android_ref` empty to use the pinned upstream commits below, or supply a tag/commit SHA to override a source explicitly. A weekly scheduled build and updates to this repository's workflow/scripts/README also trigger builds. Assets are attached to a prerelease named `Open-source client builds N` under a generated `build-N-A` tag.

## Upstream version pins

Builds do **not** track `main` or another moving branch. Defaults are commit-SHA pinned in [`upstream-versions.json`](upstream-versions.json), with the corresponding release tags recorded alongside them. The tags identify the upstream releases; the SHAs are what the build actually checks out:

| Source | Tag | Pinned commit |
| --- | --- | --- |
| [`bitwarden/clients`](https://github.com/bitwarden/clients) | `browser-v2026.10.0` | `b449ac1d255784380d75ef026343198891286be7` |
| [`bitwarden/android`](https://github.com/bitwarden/android) | `v2026.9.1-bwpm` | `770d7075cfc8e7fd5d7de6f90410585486b53206` |

These were the latest relevant stable release tags when checked on 2026-10-15 (latest browser release for the clients monorepo and latest Password Manager release for Android). The clients repository also has product-specific tags; this pin is chosen for the browser build and the desktop package is built from that same monorepo snapshot, rather than an older desktop-only release tag. The Android pin targets Password Manager (`bwpm`), not Authenticator.

To update the defaults, change the tag and commit together in `upstream-versions.json` after verifying the tag resolves to that commit and reviewing the upstream release. The workflow summary records the effective refs, and the clients preparation script logs its resolved commit. Dispatch input overrides are intentionally available for testing, but bypass the recorded defaults; use a commit SHA for reproducible overrides. Release-tag aliases can be moved upstream, so the commit SHA is the actual immutable build pin.

## Licensing / source filtering notes

- Upstream's own browser and desktop workflows distinguish OSS and commercial builds; OSS builds use their non-`bit-` scripts. This workflow removes all of `bitwarden_license/` before installing dependencies or building, rather than just omitting the particular app's matching subdirectory.
- The root upstream `package.json` in the inspected checkout also declares `@bitwarden/commercial-sdk-internal`, licensed under Bitwarden's SDK License Agreement, although it is not needed by these OSS build targets. The preparation script removes this dependency from the temporary checkout; `npm install --package-lock-only` then prunes it from the lockfile before `npm ci`.
- The root package additionally declares `@bitwarden/sdk-internal` (marked GPL-3.0 in the inspected lockfile). This is not the commercial SDK package. Normal third-party dependencies can have their own licenses; this setup does not perform a complete dependency-license audit.
- Android is built from the separate [`bitwarden/android`](https://github.com/bitwarden/android) repository using its `fdroid` flavor, not the standard flavor. The Android Gradle configuration explicitly excludes Google Play Services from F-Droid builds, while standard-only dependencies include Google Billing, Firebase, ML Kit, and Play Review. This is the intended open-source variant, but upstream flavor/dependency definitions should be reviewed as they change.
- The Android repository documents the Bitwarden SDK Maven package in GitHub Packages and says a GitHub token with `read:packages` is needed for local builds. If the default `GITHUB_TOKEN` cannot access that package in this repository's workflow, configure an `ANDROID_SDK_TOKEN` repository secret containing an appropriately authorized token. It is passed only to the Android Gradle build.
- This workflow does not compile the Angular web client or CLI. Source/package manifests, flavor dependencies, and licensing can change upstream, so review target commits and license notices before distributing generated binaries. This automation is not legal advice.

## Build details and limitations

The workflow targets Ubuntu 22.04, follows the npm workspace scripts from the pinned clients commit for browser builds, and builds the desktop native module before its `build:oss` script and electron-builder packaging. The native build requires Linux development headers including `libxss-dev`. Android is built from its pinned commit with JDK 21 and Gradle. Browser, desktop, and Android builds run as independent parallel jobs; a publish job waits for all three and attaches their artifacts plus `SOURCE-REFS.txt` to a GitHub Release. A workflow-level concurrency group allows only one build run at a time (without canceling the active run). The Firefox and Chromium ZIPs are packaged from `apps/browser/build`; the `.deb` is taken from the desktop `dist` directory; and the Android F-Droid APK is taken from `app/build/outputs/apk/fdroid/release`. Upstream changes to output paths, Node/Rust/Java requirements, or packaging configuration may require updating this workflow.

The release action requires `contents: write`, already declared at workflow level. For a public repository, builds run on upstream source, so review upstream changes and treat produced files as untrusted until validated.
