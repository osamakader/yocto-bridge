#!/usr/bin/env bash
# Wrapper script to build Yocto packages in a separate build directory
# Usage: scripts/build-yocto.sh [kas-command] [kas-options]
# Example: scripts/build-yocto.sh build
#          scripts/build-yocto.sh shell -c "bitbake busybox"
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"


BUILD_DIR="${ROOT_DIR}/build-yocto"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

kas "$@" "${ROOT_DIR}/kas/yocto-bridge.yml"

