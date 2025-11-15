#!/usr/bin/env bash
# Wrapper script to build ISAR images in a separate build directory
# Usage: scripts/build-isar.sh [kas-command] [kas-options]
# Example: scripts/build-isar.sh build
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"


BUILD_DIR="${ROOT_DIR}/build-isar"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

export KAS_CONTAINER_IMAGE=kas-hy

printf "Building ISAR image in %s\n" "${BUILD_DIR}"
printf "Using container image: %s\n" "${KAS_CONTAINER_IMAGE}"

kas-container --runtime-args "--privileged" "$@" "${ROOT_DIR}/kas/isar-build.yml"
