#!/usr/bin/env bash
# Wrapper script to build Yocto packages in a separate build directory
# Usage: scripts/build-yocto.sh [kas-command] [kas-options]
# Example: scripts/build-yocto.sh build
#          scripts/build-yocto.sh shell -c "bitbake busybox"
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# KAS creates 'build/' in the current working directory
# We use a separate directory to isolate Yocto builds
BUILD_DIR="${ROOT_DIR}/build-yocto"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Run kas - it will create build/ in this directory
kas "$@" "${ROOT_DIR}/kas/hybrid-demo.yml"

