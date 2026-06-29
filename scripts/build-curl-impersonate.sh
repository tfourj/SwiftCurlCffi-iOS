#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

build_curl_impersonate() {
  platform=$1
  sdk=$2
  src="$SOURCES_DIR/curl-impersonate"
  build_dir=$(platform_build_dir "$platform" "curl-impersonate")
  prefix=$(platform_prefix_dir "$platform" "curl-impersonate")
  sdkroot=$(sdk_path "$sdk")

  [ -d "$src" ] || die "curl-impersonate source missing; run scripts/fetch-sources.sh"
  mkdir -p "$build_dir" "$prefix"

  log "building curl-impersonate for $platform"
  cmake -S "$src" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sdkroot" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET" \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_CURL_EXE=OFF \
    -DCURL_USE_LIBPSL=OFF
  cmake --build "$build_dir"
  cmake --install "$build_dir"
}

ensure_tools
prepare_dirs

build_curl_impersonate "iphoneos" "iphoneos"
build_curl_impersonate "iphonesimulator" "iphonesimulator"

log "curl-impersonate builds are ready in $PREFIX_DIR"

