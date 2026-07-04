#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/Build}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ROOT_DIR/Artifacts}"
RESOURCES_DIR="$ROOT_DIR/Sources/SwiftCurlCffiIOS/Resources"

IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-15.0}"
PYTHON_VERSION="${PYTHON_VERSION:-3.14}"
PYTHON_TAG="${PYTHON_TAG:-cpython-314}"
CURL_CFFI_VERSION="${CURL_CFFI_VERSION:-latest}"
CURL_CFFI_ALLOW_PRERELEASES="${CURL_CFFI_ALLOW_PRERELEASES:-1}"
CFFI_VERSION="${CFFI_VERSION:-2.0.0}"
LIBFFI_VERSION="${LIBFFI_VERSION:-3.5.2}"
CURL_IMPERSONATE_REF="${CURL_IMPERSONATE_REF:-main}"

PYTHON_XCFRAMEWORK="${PYTHON_XCFRAMEWORK:-$ROOT_DIR/../Palladium/Frameworks/Python.xcframework}"
HOST_PYTHON="${HOST_PYTHON:-python3}"
SWIFTCURL_CLEAN_BUILD="${SWIFTCURL_CLEAN_BUILD:-0}"

refresh_derived_paths() {
  SOURCES_DIR="$BUILD_DIR/Sources"
  PREFIX_DIR="$BUILD_DIR/Prefix"
  RESOLVED_VERSIONS_FILE="$BUILD_DIR/resolved-versions.env"
}

refresh_derived_paths

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

print_common_usage() {
  script_name=$(basename "$0")
  cat <<EOF
Usage: $script_name [options]

Options:
  --clean
      Remove generated build outputs before running build-all.
  --curl-cffi-version VERSION
      Build a specific curl-cffi version, for example 0.15.1b1.
  --curl-cffi-allow-prereleases 0|1
      Allow prerelease curl-cffi versions when resolving latest.
  --no-curl-cffi-prereleases
      Resolve only stable curl-cffi versions.
  --cffi-version VERSION
      Build a specific cffi source version.
  --libffi-version VERSION
      Build a specific libffi source version.
  --curl-impersonate-ref REF
      Clone a specific curl-impersonate branch, tag, or commit.
  --python-xcframework PATH
      Use a specific Python.xcframework.
  --python-version VERSION
      Set the Python version written to the payload manifest.
  --python-tag TAG
      Set the Python extension tag, for example cpython-314.
  --ios-deployment-target VERSION
      Set the iOS deployment target.
  --host-python PATH
      Use a specific host Python executable.
  --build-dir PATH
      Use a specific build directory.
  --artifacts-dir PATH
      Use a specific artifacts directory.
  -h, --help
      Show this help text.

Environment variables with matching names are still supported.
EOF
}

parse_common_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --clean)
        SWIFTCURL_CLEAN_BUILD=1
        ;;
      --curl-cffi-version)
        shift
        [ "$#" -gt 0 ] || die "--curl-cffi-version requires a value"
        CURL_CFFI_VERSION=$1
        ;;
      --curl-cffi-version=*)
        CURL_CFFI_VERSION=${1#*=}
        ;;
      --curl-cffi-allow-prereleases)
        shift
        [ "$#" -gt 0 ] || die "--curl-cffi-allow-prereleases requires a value"
        CURL_CFFI_ALLOW_PRERELEASES=$1
        ;;
      --curl-cffi-allow-prereleases=*)
        CURL_CFFI_ALLOW_PRERELEASES=${1#*=}
        ;;
      --no-curl-cffi-prereleases)
        CURL_CFFI_ALLOW_PRERELEASES=0
        ;;
      --cffi-version)
        shift
        [ "$#" -gt 0 ] || die "--cffi-version requires a value"
        CFFI_VERSION=$1
        ;;
      --cffi-version=*)
        CFFI_VERSION=${1#*=}
        ;;
      --libffi-version)
        shift
        [ "$#" -gt 0 ] || die "--libffi-version requires a value"
        LIBFFI_VERSION=$1
        ;;
      --libffi-version=*)
        LIBFFI_VERSION=${1#*=}
        ;;
      --curl-impersonate-ref)
        shift
        [ "$#" -gt 0 ] || die "--curl-impersonate-ref requires a value"
        CURL_IMPERSONATE_REF=$1
        ;;
      --curl-impersonate-ref=*)
        CURL_IMPERSONATE_REF=${1#*=}
        ;;
      --python-xcframework)
        shift
        [ "$#" -gt 0 ] || die "--python-xcframework requires a value"
        PYTHON_XCFRAMEWORK=$1
        ;;
      --python-xcframework=*)
        PYTHON_XCFRAMEWORK=${1#*=}
        ;;
      --python-version)
        shift
        [ "$#" -gt 0 ] || die "--python-version requires a value"
        PYTHON_VERSION=$1
        ;;
      --python-version=*)
        PYTHON_VERSION=${1#*=}
        ;;
      --python-tag)
        shift
        [ "$#" -gt 0 ] || die "--python-tag requires a value"
        PYTHON_TAG=$1
        ;;
      --python-tag=*)
        PYTHON_TAG=${1#*=}
        ;;
      --ios-deployment-target)
        shift
        [ "$#" -gt 0 ] || die "--ios-deployment-target requires a value"
        IOS_DEPLOYMENT_TARGET=$1
        ;;
      --ios-deployment-target=*)
        IOS_DEPLOYMENT_TARGET=${1#*=}
        ;;
      --host-python)
        shift
        [ "$#" -gt 0 ] || die "--host-python requires a value"
        HOST_PYTHON=$1
        ;;
      --host-python=*)
        HOST_PYTHON=${1#*=}
        ;;
      --build-dir)
        shift
        [ "$#" -gt 0 ] || die "--build-dir requires a value"
        BUILD_DIR=$1
        ;;
      --build-dir=*)
        BUILD_DIR=${1#*=}
        ;;
      --artifacts-dir)
        shift
        [ "$#" -gt 0 ] || die "--artifacts-dir requires a value"
        ARTIFACTS_DIR=$1
        ;;
      --artifacts-dir=*)
        ARTIFACTS_DIR=${1#*=}
        ;;
      -h|--help)
        print_common_usage
        exit 0
        ;;
      --)
        shift
        [ "$#" -eq 0 ] || die "unexpected argument after --: $1"
        break
        ;;
      --*)
        die "unknown option: $1"
        ;;
      *)
        die "unexpected argument: $1"
        ;;
    esac
    shift
  done

  refresh_derived_paths
  export_common_config
}

export_common_config() {
  export \
    BUILD_DIR \
    ARTIFACTS_DIR \
    IOS_DEPLOYMENT_TARGET \
    PYTHON_VERSION \
    PYTHON_TAG \
    CURL_CFFI_VERSION \
    CURL_CFFI_ALLOW_PRERELEASES \
    CFFI_VERSION \
    LIBFFI_VERSION \
    CURL_IMPERSONATE_REF \
    PYTHON_XCFRAMEWORK \
    HOST_PYTHON \
    SWIFTCURL_CLEAN_BUILD
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

version_from_sdist_archive() {
  archive=$1
  pkg_info=$(tar -tzf "$archive" | grep '/PKG-INFO$' | head -1 || true)
  [ -n "$pkg_info" ] || return 1

  tar -xOzf "$archive" "$pkg_info" \
    | awk -F': ' 'tolower($1) == "version" { print $2; exit }'
}

version_from_source_dir() {
  src=$1
  [ -f "$src/PKG-INFO" ] || return 1

  awk -F': ' 'tolower($1) == "version" { print $2; exit }' "$src/PKG-INFO"
}

record_resolved_version() {
  key=$1
  version=$2
  tmp="$RESOLVED_VERSIONS_FILE.tmp"

  mkdir -p "$BUILD_DIR"
  if [ -f "$RESOLVED_VERSIONS_FILE" ]; then
    grep -v "^$key='" "$RESOLVED_VERSIONS_FILE" > "$tmp" || true
  else
    : > "$tmp"
  fi
  printf "%s='%s'\n" "$key" "$version" >> "$tmp"
  mv "$tmp" "$RESOLVED_VERSIONS_FILE"
}

read_resolved_version() {
  key=$1
  [ -f "$RESOLVED_VERSIONS_FILE" ] || return 1

  sed -n "s/^$key='\(.*\)'$/\1/p" "$RESOLVED_VERSIONS_FILE" | tail -1
}

effective_package_version() {
  key=$1
  requested=$2
  src=$3
  label=$4

  version=$(read_resolved_version "$key" || true)
  if [ -z "$version" ]; then
    version=$(version_from_source_dir "$src" || true)
  fi
  if [ -z "$version" ] && [ "$requested" != "latest" ]; then
    version=$requested
  fi
  [ -n "$version" ] || die "$label version unresolved; run scripts/fetch-sources.sh first"

  printf '%s\n' "$version"
}
