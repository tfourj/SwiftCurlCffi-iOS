# Palladium Integration Notes

The generated payload is not a normal PyPI wheel. Palladium should treat it as a
prebuilt, app-bundled Python package payload.

## Install Location

During Palladium's Xcode build:

1. Unzip `curl_cffi_ios_payload.zip`.
2. Pick `site-packages-iphoneos` on device and `site-packages-iphonesimulator`
   on Simulator.
3. Copy the selected directory contents into the built app bundle's
   `python-packages` directory.
4. Pass `python-packages` to `install_python` so extension `.so` files are
   converted into iOS frameworks.

## Xcode Build Phase

Palladium's Python helper converts Python extension `.so` files into iOS
frameworks when the package path is passed to `install_python`.

```sh
install_python Frameworks/Python.xcframework python-packages
```

Palladium reads the zip from the copied local dependency path:

```text
Frameworks/SwiftCurlCffi-iOS/Sources/SwiftCurlCffiIOS/Resources/curl_cffi_ios_payload.zip
```

## Runtime Package Management

Once bundled, Palladium should avoid `pip install curl-cffi` on iOS. The pip
fallback downloads the source distribution and fails because no iOS wheel exists
on PyPI.

Palladium exposes the bundled package path through
`PALLADIUM_BUNDLED_PYTHON_PACKAGES` and keeps normal pip management for
`yt-dlp`, `yt-dlp-apple-webkit-jsi`, `gallery-dl`, and `pip`.
