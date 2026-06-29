#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

copy_python_sources() {
  payload=$1

  mkdir -p "$payload"
  "$HOST_PYTHON" -m pip install \
    --target "$payload" \
    --no-binary :all: \
    --no-deps \
    --no-build-isolation \
    "certifi" "pycparser"

  [ -d "$SOURCES_DIR/cffi/src/cffi" ] || die "cffi source missing; run scripts/fetch-sources.sh"
  [ -d "$SOURCES_DIR/curl_cffi/curl_cffi" ] || die "curl_cffi source missing; run scripts/fetch-sources.sh"

  rm -rf "$payload/cffi" "$payload/curl_cffi"
  cp -R "$SOURCES_DIR/cffi/src/cffi" "$payload/cffi"
  cp -R "$SOURCES_DIR/curl_cffi/curl_cffi" "$payload/curl_cffi"
}

build_cffi_backend() {
  platform=$1
  sdk=$2
  payload=$3
  src="$SOURCES_DIR/cffi"
  prefix=$(platform_prefix_dir "$platform" "libffi")
  out_suffix=$(extension_suffix_for_platform "$platform")
  out="$payload/_cffi_backend$out_suffix"
  cc=$(clang_for_sdk "$sdk")
  sdkroot=$(sdk_path "$sdk")
  py_headers=$(python_headers_for_platform "$platform")
  py_framework_parent=$(python_framework_parent_for_platform "$platform")
  min_flag=$(min_version_flag_for_platform "$platform")
  install_name=$(module_install_name "_cffi_backend" "$platform")

  [ -f "$src/src/c/_cffi_backend.c" ] || die "missing cffi backend source"
  [ -d "$prefix/include" ] || die "missing libffi prefix for $platform; run scripts/build-libffi.sh"

  log "building _cffi_backend for $platform"
  "$cc" -dynamiclib -fPIC -arch arm64 \
    -isysroot "$sdkroot" \
    "$min_flag" \
    -I"$py_headers" \
    -I"$prefix/include" \
    -F"$py_framework_parent" \
    "$src/src/c/_cffi_backend.c" \
    "$prefix/lib/libffi.a" \
    -framework Python \
    -framework CoreFoundation \
    -install_name "$install_name" \
    -o "$out"
}

generate_curl_cffi_wrapper() {
  wrapper="$SOURCES_DIR/curl_cffi/curl_cffi/_wrapper.c"
  if [ -f "$wrapper" ]; then
    return
  fi

  log "generating curl_cffi CFFI wrapper"
  (
    cd "$SOURCES_DIR/curl_cffi"
    "$HOST_PYTHON" scripts/build.py
  )
}

build_curl_cffi_wrapper() {
  platform=$1
  sdk=$2
  payload=$3
  src="$SOURCES_DIR/curl_cffi"
  curl_prefix=$(platform_prefix_dir "$platform" "curl-impersonate")
  out_suffix=$(extension_suffix_for_platform "$platform")
  out="$payload/curl_cffi/_wrapper$out_suffix"
  cc=$(clang_for_sdk "$sdk")
  sdkroot=$(sdk_path "$sdk")
  py_headers=$(python_headers_for_platform "$platform")
  py_framework_parent=$(python_framework_parent_for_platform "$platform")
  min_flag=$(min_version_flag_for_platform "$platform")
  install_name=$(module_install_name "curl_cffi._wrapper" "$platform")

  [ -f "$src/curl_cffi/_wrapper.c" ] || die "missing generated curl_cffi wrapper"
  [ -d "$curl_prefix/include" ] || die "missing curl-impersonate prefix for $platform"
  curl_archive=$(find "$curl_prefix/lib" -name 'libcurl*.a' -print | head -1 || true)
  [ -n "$curl_archive" ] || die "missing curl static library for $platform"

  log "building curl_cffi wrapper for $platform"
  "$cc" -dynamiclib -fPIC -arch arm64 \
    -isysroot "$sdkroot" \
    "$min_flag" \
    -I"$py_headers" \
    -I"$curl_prefix/include" \
    -F"$py_framework_parent" \
    "$src/curl_cffi/_wrapper.c" \
    "$curl_archive" \
    -framework Python \
    -framework CoreFoundation \
    -framework Security \
    -framework SystemConfiguration \
    -lz \
    -install_name "$install_name" \
    -o "$out"
}

write_manifest() {
  payload=$1
  manifest=$2
  cat > "$manifest" <<EOF
{
  "curl_cffi": "$CURL_CFFI_VERSION",
  "cffi": "$CFFI_VERSION",
  "libffi": "$LIBFFI_VERSION",
  "python": "$PYTHON_VERSION",
  "platforms": ["iphoneos-arm64", "iphonesimulator-arm64"],
  "payload": "$(basename "$payload")"
}
EOF
}

ensure_tools
ensure_python_xcframework
prepare_dirs

PAYLOAD_DIR="$ARTIFACTS_DIR/curl_cffi_ios_payload"
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR/site-packages-iphoneos" "$PAYLOAD_DIR/site-packages-iphonesimulator"

copy_python_sources "$PAYLOAD_DIR/site-packages-iphoneos"
copy_python_sources "$PAYLOAD_DIR/site-packages-iphonesimulator"
generate_curl_cffi_wrapper

build_cffi_backend "iphoneos" "iphoneos" "$PAYLOAD_DIR/site-packages-iphoneos"
build_cffi_backend "iphonesimulator" "iphonesimulator" "$PAYLOAD_DIR/site-packages-iphonesimulator"
build_curl_cffi_wrapper "iphoneos" "iphoneos" "$PAYLOAD_DIR/site-packages-iphoneos"
build_curl_cffi_wrapper "iphonesimulator" "iphonesimulator" "$PAYLOAD_DIR/site-packages-iphonesimulator"

write_manifest "$PAYLOAD_DIR" "$PAYLOAD_DIR/manifest.json"

rm -f "$RESOURCES_DIR/curl_cffi_ios_payload.zip" "$RESOURCES_DIR/manifest.json"
(
  cd "$ARTIFACTS_DIR"
  zip -qry "$RESOURCES_DIR/curl_cffi_ios_payload.zip" "curl_cffi_ios_payload"
)
cp "$PAYLOAD_DIR/manifest.json" "$RESOURCES_DIR/manifest.json"
touch "$RESOURCES_DIR/.artifact-ready"

log "payload written to $PAYLOAD_DIR"
log "Swift package resource written to $RESOURCES_DIR/curl_cffi_ios_payload.zip"
