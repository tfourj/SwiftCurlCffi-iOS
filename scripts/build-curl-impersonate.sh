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
  apply_ios_curl_cache_patch "$src"

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

apply_ios_curl_cache_patch() {
  src=$1
  cmake_file="$src/CMakeLists.txt"
  marker="SwiftCurlCffi-iOS disable pipe2 cache"

  [ -f "$cmake_file" ] || die "curl-impersonate CMakeLists missing: $cmake_file"
  if grep -q "$marker" "$cmake_file"; then
    return
  fi

  perl -0pi -e 's/set\(_curl_platform_flags\)\n/set(_curl_platform_flags)\nif(CMAKE_SYSTEM_NAME STREQUAL "iOS") # SwiftCurlCffi-iOS disable pipe2 cache\n  list(APPEND _curl_platform_flags "-DHAVE_PIPE2=0")\nendif()\n/' "$cmake_file"
}

ensure_tools
prepare_dirs

build_curl_impersonate "iphoneos" "iphoneos"
build_curl_impersonate "iphonesimulator" "iphonesimulator"

log "curl-impersonate builds are ready in $PREFIX_DIR"
