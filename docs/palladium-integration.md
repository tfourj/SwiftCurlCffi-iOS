# Palladium Integration Notes

The generated payload is not a normal PyPI wheel. Palladium should treat it as a
prebuilt, app-bundled Python package payload.

## Install Location

At app startup or package-maintenance time:

1. Unzip `curl_cffi_ios_payload.zip`.
2. Pick `site-packages-iphoneos` on device and `site-packages-iphonesimulator`
   on Simulator.
3. Copy the selected directory contents into Palladium's
   `PALLADIUM_PYTHON_PACKAGES` directory.

## Xcode Build Phase

Palladium's Python helper can convert Python extension `.so` files into iOS
frameworks if the package path is passed to `install_python`.

The current call:

```sh
install_python Frameworks/Python.xcframework
```

will need to become something like:

```sh
install_python Frameworks/Python.xcframework python-packages
```

or another bundle-relative path that contains the prebuilt payload during the
Xcode build.

## Runtime Package Management

Once bundled, Palladium should avoid `pip install curl-cffi` on iOS. The pip
fallback downloads the source distribution and fails because no iOS wheel exists
on PyPI.

