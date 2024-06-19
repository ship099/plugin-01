#!/usr/bin/env sh

#
#  Copyright (c) 2016 SourceClear Inc
#

# For more verbose output, run with 'DEBUG=1 path/to/ci.sh'
# To force download of latest version, run with 'NOCACHE=1 path/to/ci.sh'
# To change where archives are cached and extracted, run with 'CACHE_DIR=/where/you/want/them path/to/ci.sh'
# To retrieve and unpack the agent without actually running it, run with 'NOSCAN=1'
# These values may be stored in the environment and combined in any way you see fit.

CACHE_DIR=${CACHE_DIR:-/tmp}
DEBUG=${DEBUG:-0}
NOCACHE=${NOCACHE:-0}
NOSCAN=${NOSCAN:-0}
SCAN_DIR="${SCAN_DIR:-}"  # may be set as the directory other than $PWD to scan
SRCCLR_CI_JSON=${SRCCLR_CI_JSON:-0}
VERBOSE=${VERBOSE:-0}

main() {
  debug_runtime_options
  check_binaries
  check_architecture
  check_and_set_OS
  create_temp_folder
  if [ "$SRCCLR_VERSION" ]; then
    debug "main: SRCCLR_VERSION is set to $SRCCLR_VERSION"
    version=$SRCCLR_VERSION
    download
  else
    check_and_set_latest_version || download
  fi
  extract

  run_scan "$@"
}

debug() {
  [ ${DEBUG} -ge 1 ] && echo "debug: $@" >&2
}

debug_runtime_options() {
  debug 'DEBUG is enabled'
  if [ ${NOCACHE} -eq 0 ]; then
    debug 'NOCACHE is 0 or unset; cache will be used normally'
  else
    debug 'NOCACHE set to non-zero; cache will be ignored'
  fi
  debug "CACHE_DIR is \"${CACHE_DIR}\"; archives will be saved and extracted into it"

  if [ ${NOSCAN} -eq 0 ]; then
    debug 'NOSCAN is 0 or unset; scan will be performed'
  else
    debug 'NOSCAN is set to non-zero; scan will be skipped'
  fi
}

check_binaries() {
  local rc=0
  for binary in curl date mktemp tar uname gzip; do
    if type $binary > /dev/null; then
      debug "check_binaries: checking for $binary: OK"
    else
      echo "$binary is required to continue, but could not be found on your system." >&2
      rc=1
    fi
  done
  if [ $rc != 0 ]; then
    exit $rc
  fi
}

check_architecture() {
  #
  # Only support 64 bit Linux | Darwin
  #
  local arch=$(uname -m)
  local kernel=$(uname -s)
  debug "check_architecture: architecture: ${arch}"    
  if [ "z${arch}" != "zx86_64" ]; then
    if [ "${kernel}" = "Darwin" ]; then
      echo "warning: Veracode doesn't ship an arm64 specific agent. As Mac M1 can run x86 agent we are proceeding"
      return 0
    fi  
    debug "check_architecture: architecture is not x86_64"
    echo "error: Veracode SCA CI only supports x86_64, but your uname -m reported '${arch}'" >&2
    exit 1
  fi
}

check_and_set_OS() {
  local kernel=$(uname -s)
  debug "check_and_set_OS: kernel: ${kernel}"
  case ${kernel} in
    linux|Linux)
      if [ -e /etc/os-release ] && (grep -q alpine /etc/os-release) ; then
        OS=linux_musl_x64; debug "check_and_set_OS: Linux (musl) Kernel OK"
      else
        OS=linux; debug "check_and_set_OS: Linux (glibc) Kernel OK"
      fi
      ;;
    darwin|Darwin)
      OS=macosx; debug "check_and_set_OS: Mac OS X Kernel OK"
      ;;
    *)
      debug "check_and_set_OS: Kernel not recognized"
      echo "error: Veracode SCA CI only supports Linux or Darwin, but your uname -s reported '${kernel}'" >&2
      exit 1
      ;;
  esac
}

create_temp_folder() {
  FOLDER="$(mktemp -q -d -t srcclr.XXXXXX 2>/dev/null || mktemp -q -d)"
  debug "create_temp_folder: Using $FOLDER as temporary folder."
  cleanup() {
    C=$?
    debug "create_temp_folder: cleanup: cleaning up \"$FOLDER\""
    rm -rf "$FOLDER"
    trap - EXIT
    exit $C
  }
  trap cleanup EXIT INT
}

# Returns 0 if the latest version tgz appears to be present; otherwise 1.
check_and_set_latest_version() {
  debug "check_and_set_latest_version: checking latest version..."
  if curl -m30 -f -v -o "$FOLDER/version" https://download.sourceclear.com/LATEST_VERSION 2>"$FOLDER/curl-output"; then
    version=$(cat "$FOLDER/version")
    debug "check_and_set_latest_version: retrieved LATEST_VERSION: $version"
    if [ ${NOCACHE} -eq 0 -a -e "${CACHE_DIR}/srcclr-${version}-${OS}.tgz" ]; then
      debug "check_and_set_latest_version: latest version already exists."
      return 0
    fi
    debug "check_and_set_latest_version: latest version does not exist and will be downloaded."
    return 1
  else
    debug "check_and_set_latest_version: retrieving LATEST_VERSION failed: $?"
    echo "warning: we were not able to retrieve LATEST_VERSION, and will therefore not used the locally cached agent" >&2
    echo "warning: curl provided the following output, which may be useful for debugging:" >&2
    cat "$FOLDER/curl-output" >&2
    version="latest"
    return 1
  fi
}

download() {
  local url="https://download.sourceclear.com/srcclr-${version}-$OS.tgz"
  debug "download: retrieving srcclr v${version} for ${OS} via ${url}..."
  local t0=$(date +%s)
  if curl -m 300 -f -v -o "$FOLDER/srcclr-${version}-${OS}.tgz" "${url}" 2>"$FOLDER/curl-output"; then
    debug "download: retrieved in $(( $(date +%s) - $t0 ))s."
    if [ ! -d "$CACHE_DIR" ]; then
      mkdir "$CACHE_DIR"
    fi
    mv "$FOLDER/srcclr-${version}-${OS}.tgz" "${CACHE_DIR}"
  else
    debug "download: retrieval failed: $?"
    echo "We were not able to download your installation package from ${url}." >&2
    echo "Curl provided the following output, which may be useful for debugging:" >&2
    cat "$FOLDER/curl-output" >&2
    exit 1
  fi
}

extract() {
  # Check if the version is already extracted
  if [ ${NOCACHE} -eq 0 -a -d "${CACHE_DIR}/srcclr" -a -e "${CACHE_DIR}/srcclr/VERSION" ] \
    && [ "z$(cat "${CACHE_DIR}/srcclr/VERSION")" = "z${version}" ]; then
    debug "extract: version is already extracted; skipping."
    return 0
  else
    debug "extract: version not extracted; continuing."
  fi

  # Check to make sure the archive exists.
  if [ ! -e "${CACHE_DIR}/srcclr-${version}-${OS}.tgz" ]; then
    echo "error: extract expected \"${CACHE_DIR}/srcclr-${version}-${OS}.tgz\" to exist, but file is not found." >&2
    exit 1
  else
    debug "extract: archive \"${CACHE_DIR}/srcclr-${version}-${OS}.tgz\" found"
  fi

  rm -rf "${CACHE_DIR}/srcclr" || true

  if mkdir -p "${CACHE_DIR}/srcclr"; then
    debug "extract: \"${CACHE_DIR}/srcclr\" created"
  else
    echo "error: extract: failed to create target directory \"${CACHE_DIR}/srcclr\": $?" >&2
    exit 1
  fi

  debug "extract: extracting srcclr..."
  local t0=$(date +%s)
  if tar xzf "${CACHE_DIR}/srcclr-${version}-${OS}.tgz" -C "${CACHE_DIR}/srcclr" --strip-components=1; then
    debug "extract: extraction complete in $(( $(date +%s) - $t0 ))s."
  else
    debug "extract: extraction failed: $?"
    echo "error: extract: tar reported errors while extracting the srcclr package." >&2
    exit 1
  fi
}

run_scan() {
  #
  # Actually perform the scan on the current folder, or "$SCAN_DIR" if set
  #
  if [ ${NOSCAN} -ne 0 ]; then
    debug "run_scan: NOSCAN is set; returning"
    return 0
  fi
  debug "run_scan entry: $@"

  # when updating these, be cognizant whether "left" or "right" of the verb
  # and if they provided no other args, "scan --dirty" it is
  if [ $# -eq 0 ]; then
    set -- scan --allow-dirty
  fi
  if [ ${DEBUG} -ge 1 ]; then
    set -- --debug "$@"
  fi

  if [ ${VERBOSE} -ge 1 ]; then
    set -- "$@" --loud
  fi

  if [ ${SRCCLR_CI_JSON} -ge 1 ]; then
    set -- "$@" --json
  fi
  if [ "$SCAN_DIR" ]; then
    set -- "$@" "$SCAN_DIR"
  fi

  debug "run_scan: running \"${CACHE_DIR}/srcclr/bin/srcclr\" $@"
  exec "${CACHE_DIR}/srcclr/bin/srcclr" "$@"
}

main "$@"
