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

The Swift target exposes those resources through `SwiftCurlCffiIOS.payloadURL`
and `SwiftCurlCffiIOS.manifestURL`.

## Requirements

- macOS with Xcode command line tools
- `cmake`
- `ninja`
- `curl`
- `tar`
- a host Python matching the embedded app Python minor version
- Palladium's `Python.xcframework`

Defaults target Python `3.14` because Palladium currently bundles Python 3.14.

## Build

From this repo:

```sh
PYTHON_XCFRAMEWORK=/path/to/Python.xcframework ./scripts/build-all.sh
```

When this repo is checked out next to Palladium, the default works:

```sh
./scripts/build-all.sh
```

## Export To Palladium

After a successful build:

```sh
PALLADIUM_ROOT=/path/to/Palladium ./scripts/export-to-palladium.sh
```

This copies the generated Swift package resources into Palladium's dependency
checkout location. Palladium still needs integration code that unpacks the
payload into its app support Python package directory and calls Python's
`install_python` helper with that package path so `.so` files are converted
into loadable iOS frameworks at build time.

## Current Limits

The scripts build the native pieces outside the iOS sandbox. They intentionally
do not attempt to run `pip install curl-cffi` on-device. If upstream changes
`curl-cffi`, `cffi`, or `curl-impersonate` build internals, the Python package
staging script may need updates.

