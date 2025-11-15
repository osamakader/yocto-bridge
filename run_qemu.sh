#!/usr/bin/env bash
set -e

# Try both .build-isar and build-isar
if [[ -d ".build-isar/build/tmp/deploy/images/qemuarm64" ]]; then
    IMAGE_DIR=".build-isar/build/tmp/deploy/images/qemuarm64"
elif [[ -d "build-isar/build/tmp/deploy/images/qemuarm64" ]]; then
    IMAGE_DIR="build-isar/build/tmp/deploy/images/qemuarm64"
else
    echo "Error: Image directory not found. Please build the ISAR image first." >&2
    exit 1
fi
KERNEL="${IMAGE_DIR}/isar-image-base-debian-bookworm-qemuarm64-vmlinux"
INITRD="${IMAGE_DIR}/isar-image-base-debian-bookworm-qemuarm64-initrd.img"
ROOTFS="${IMAGE_DIR}/isar-image-base-debian-bookworm-qemuarm64.ext4"

if [[ ! -f "${KERNEL}" ]] || [[ ! -f "${INITRD}" ]] || [[ ! -f "${ROOTFS}" ]]; then
    echo "Error: Required image files not found in ${IMAGE_DIR}" >&2
    exit 1
fi

# QEMU command for ARM64 virt machine
# Use -device virtio-blk-device (not virtio-blk-pci) for ARM64 virt machine
# The Debian kernel should have virtio_blk built-in, so modules aren't needed
# But we need to ensure the device appears with the right name
qemu-system-aarch64 \
    -machine virt -cpu cortex-a57 -m 1024 \
    -nographic \
    -kernel "${KERNEL}" \
    -append "root=/dev/vda console=ttyAMA0 rw rootwait rootdelay=10 modules-load=virtio_blk,virtio_net,virtio,virtio_pci,virtio_mmio" \
    -drive file="${ROOTFS}",format=raw,if=virtio,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-device,netdev=net0 \
    -initrd "${INITRD}"
