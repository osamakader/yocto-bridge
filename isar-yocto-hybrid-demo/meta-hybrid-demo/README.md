# meta-hybrid-demo Layer

This Yocto/BitBake layer provides the minimal glue needed to rebuild a small set of components from source while ISAR supplies the rest of the system as prebuilt Debian packages.

## Layout
- `recipes-kernel/linux/linux-yocto_%.bbappend` — Hooks to patch or reconfigure the QEMU kernel used by the ISAR image.
- `recipes-core/containerd/containerd_%.bbappend` — Demonstrates overriding a user-space package.
- `recipes-kernel/linux/linux-yocto/files/rt-kernel.cfg` — Optional PREEMPT_RT fragment injected into the kernel config.

Add further `.bbappend` files under the usual Yocto directory structure when more components need customization.

## Usage
1. Edit the `.bbappend` files to point at your git repositories or apply patches.
2. Run `kas shell ../kas/hybrid-demo.yml --command "bitbake isar-image-base"` to build the hybrid image.
3. Inspect build reuse metrics via `../scripts/hybrid-build-stats.sh`.

