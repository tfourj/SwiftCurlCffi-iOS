#!/bin/sh
set -eu

. "$(dirname "$0")/common.sh"

parse_common_args "$@"

build_libffi() {
  platform=$1
  sdk=$2
  host=$3
  min_flag=$4
  src="$SOURCES_DIR/libffi"
  build_dir=$(platform_build_dir "$platform" "libffi")
  prefix=$(platform_prefix_dir "$platform" "libffi")
  cc=$(clang_for_sdk "$sdk")
  sdkroot=$(sdk_path "$sdk")

  [ -d "$src" ] || die "libffi source missing; run scripts/fetch-sources.sh"
  mkdir -p "$build_dir" "$prefix"

  log "building libffi for $platform"
  (
    cd "$build_dir"
    CC="$cc" \
    CFLAGS="-arch arm64 -isysroot $sdkroot $min_flag -fembed-bitcode=off" \
    LDFLAGS="-arch arm64 -isysroot $sdkroot $min_flag" \
      "$src/configure" \
        --host="$host" \
        --prefix="$prefix" \
        --disable-shared \
        --enable-static
    make -j"$(sysctl -n hw.ncpu)"
    make install
  )
}

ensure_tools
prepare_dirs

build_libffi "iphoneos" "iphoneos" "aarch64-apple-darwin" "-miphoneos-version-min=$IOS_DEPLOYMENT_TARGET"
build_libffi "iphonesimulator" "iphonesimulator" "aarch64-apple-darwin" \
  "-mios-simulator-version-min=$IOS_DEPLOYMENT_TARGET"

log "libffi builds are ready in $PREFIX_DIR"
