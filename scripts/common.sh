#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/Build}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ROOT_DIR/Artifacts}"
SOURCES_DIR="$BUILD_DIR/Sources"
PREFIX_DIR="$BUILD_DIR/Prefix"
RESOURCES_DIR="$ROOT_DIR/Sources/SwiftCurlCffiIOS/Resources"

IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-15.0}"
PYTHON_VERSION="${PYTHON_VERSION:-3.14}"
PYTHON_TAG="${PYTHON_TAG:-cpython-314}"
CURL_CFFI_VERSION="${CURL_CFFI_VERSION:-0.15.1b2}"
CFFI_VERSION="${CFFI_VERSION:-2.0.0}"
LIBFFI_VERSION="${LIBFFI_VERSION:-3.5.2}"
CURL_IMPERSONATE_REF="${CURL_IMPERSONATE_REF:-main}"

PYTHON_XCFRAMEWORK="${PYTHON_XCFRAMEWORK:-$ROOT_DIR/../Palladium/Frameworks/Python.xcframework}"
HOST_PYTHON="${HOST_PYTHON:-python3}"

log() {
  printf '[SwiftCurlCffi-iOS] %s\n' "$*"
}

die() {
  printf '[SwiftCurlCffi-iOS] error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

ensure_tools() {
  require_command xcrun
  require_command cmake
  require_command ninja
  require_command curl
  require_command tar
  require_command "$HOST_PYTHON"
}

ensure_python_xcframework() {
  [ -d "$PYTHON_XCFRAMEWORK" ] || die "Python.xcframework not found: $PYTHON_XCFRAMEWORK"
  [ -d "$PYTHON_XCFRAMEWORK/ios-arm64/Python.framework/Headers" ] || \
    die "missing iphoneos Python headers in $PYTHON_XCFRAMEWORK"
}

sdk_path() {
  xcrun --sdk "$1" --show-sdk-path
}

clang_for_sdk() {
  xcrun --sdk "$1" --find clang
}

python_headers_for_platform() {
  case "$1" in
    iphoneos)
      printf '%s/ios-arm64/Python.framework/Headers\n' "$PYTHON_XCFRAMEWORK"
      ;;
    iphonesimulator)
      if [ -d "$PYTHON_XCFRAMEWORK/ios-arm64-simulator/Python.framework/Headers" ]; then
        printf '%s/ios-arm64-simulator/Python.framework/Headers\n' "$PYTHON_XCFRAMEWORK"
      else
        printf '%s/ios-arm64_x86_64-simulator/Python.framework/Headers\n' "$PYTHON_XCFRAMEWORK"
      fi
      ;;
    *)
      die "unsupported platform: $1"
      ;;
  esac
}

python_framework_parent_for_platform() {
  case "$1" in
    iphoneos)
      printf '%s/ios-arm64\n' "$PYTHON_XCFRAMEWORK"
      ;;
    iphonesimulator)
      if [ -d "$PYTHON_XCFRAMEWORK/ios-arm64-simulator/Python.framework" ]; then
        printf '%s/ios-arm64-simulator\n' "$PYTHON_XCFRAMEWORK"
      else
        printf '%s/ios-arm64_x86_64-simulator\n' "$PYTHON_XCFRAMEWORK"
      fi
      ;;
    *)
      die "unsupported platform: $1"
      ;;
  esac
}

min_version_flag_for_platform() {
  case "$1" in
    iphoneos)
      printf '%s\n' "-miphoneos-version-min=$IOS_DEPLOYMENT_TARGET"
      ;;
    iphonesimulator)
      printf '%s\n' "-mios-simulator-version-min=$IOS_DEPLOYMENT_TARGET"
      ;;
    *)
      die "unsupported platform: $1"
      ;;
  esac
}

extension_suffix_for_platform() {
  case "$1" in
    iphoneos)
      printf '.%s-iphoneos.so\n' "$PYTHON_TAG"
      ;;
    iphonesimulator)
      printf '.%s-iphonesimulator.so\n' "$PYTHON_TAG"
      ;;
    *)
      die "unsupported platform: $1"
      ;;
  esac
}

module_install_name() {
  module_name=$1
  platform=$2
  suffix=$(extension_suffix_for_platform "$platform")
  printf 'Modules/%s%s\n' "$module_name" "$suffix"
}

platform_build_dir() {
  printf '%s/%s/%s\n' "$BUILD_DIR" "$1" "$2"
}

platform_prefix_dir() {
  printf '%s/%s/%s\n' "$PREFIX_DIR" "$1" "$2"
}

prepare_dirs() {
  mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR" "$SOURCES_DIR" "$PREFIX_DIR" "$RESOURCES_DIR"
}
