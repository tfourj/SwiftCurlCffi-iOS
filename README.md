# SwiftCurlCffi-iOS

SwiftCurlCffi-iOS is a build wrapper for producing an iOS-ready Python payload
for `curl_cffi`, `cffi`, and the native `curl-impersonate` libraries needed by
yt-dlp impersonation extractors.

This repo exists because PyPI does not publish iOS wheels for `curl-cffi`.
Installing `curl-cffi` directly inside an iOS app falls back to the source
distribution, which requires a compiler, build dependencies, and native
libraries that are not available inside the app sandbox.

## Output

The build scripts stage a payload at:

```text
Artifacts/curl_cffi_ios_payload/
```

and zip it into:

```text
Sources/SwiftCurlCffiIOS/Resources/curl_cffi_ios_payload.zip
Sources/SwiftCurlCffiIOS/Resources/manifest.json
```

The Swift target is a lightweight marker library. The payload resources are
excluded from SwiftPM resource processing so Palladium's build script can unpack
and process them once from the copied `Frameworks/SwiftCurlCffi-iOS` checkout.

## Requirements

- macOS with Xcode command line tools
- `cmake`
- `ninja`
- `curl`
- `tar`
- a host Python matching the embedded app Python minor version
- Palladium's `Python.xcframework`

Defaults target Python `3.14` because Palladium currently bundles Python 3.14.
`curl-cffi` defaults to `latest`, with prereleases allowed because Python 3.14
support may land in prerelease builds first.

The build must run on macOS with Xcode because it uses `xcrun`, Apple iOS SDKs,
and the iPhoneOS/iPhoneSimulator arm64 toolchains. GitHub-hosted Ubuntu runners
do not include the Apple SDK or a legal Xcode toolchain.

## Build

From this repo:

```sh
PYTHON_XCFRAMEWORK=/path/to/Python.xcframework ./scripts/build-all.sh
```

When this repo is checked out next to Palladium, the default works:

```sh
./scripts/build-all.sh
```

To pin a specific curl-cffi release instead:

```sh
CURL_CFFI_VERSION=0.15.1b2 ./scripts/build-all.sh
```

To resolve only stable curl-cffi releases:

```sh
CURL_CFFI_ALLOW_PRERELEASES=0 ./scripts/build-all.sh
```

For local rebuilds, run `./scripts/clean.sh` first if an older source checkout
has already been fetched.

## Release Zip

After a successful build, package the local checkout and generated payload into
the zip consumed by Palladium:

```sh
./scripts/package-release.sh
```

This writes:

```text
Dist/SwiftCurlCffi-iOS.zip
```

The GitHub Actions workflow builds the same zip. Pushes upload it as a workflow
artifact, and tag builds publish it as a GitHub release asset named
`SwiftCurlCffi-iOS.zip`.

## Export To Palladium

After a successful build:

```sh
PALLADIUM_ROOT=/path/to/Palladium ./scripts/export-to-palladium.sh
```

This copies the generated Swift package resources into Palladium's dependency
checkout location. Palladium's Xcode build script unpacks the platform-specific
payload into the app bundle's `python-packages` directory and calls Python's
`install_python` helper with that package path so `.so` files are converted
into loadable iOS frameworks at build time.

## Current Limits

The scripts build the native pieces outside the iOS sandbox. They intentionally
do not attempt to run `pip install curl-cffi` on-device. If upstream changes
`curl-cffi`, `cffi`, or `curl-impersonate` build internals, the Python package
staging script may need updates.
