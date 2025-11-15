#!/usr/bin/env bash
# Wrapper script to build ISAR images in a separate build directory
# Usage: scripts/build-isar.sh [kas-command] [kas-options]
# Example: scripts/build-isar.sh build
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# KAS creates 'build/' in the current working directory
# We use a separate directory to isolate ISAR builds
BUILD_DIR="${ROOT_DIR}/build-isar"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Run kas - it will create build/ in this directory
KAS_CONTAINER_IMAGE=kas-hy kas-container "$@" "${ROOT_DIR}/kas/isar-build.yml"

