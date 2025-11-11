# meta-hybrid-demo Layer

This Yocto/BitBake layer provides the minimal glue needed to rebuild BusyBox from source while ISAR supplies the rest of the system as prebuilt Debian packages.

## Layout
- `recipes-core/busybox/busybox_%.bbappend` — Demonstrates overriding a user-space package.

Add further `.bbappend` files under the usual Yocto directory structure when more components need customization.

## Usage
1. Edit the BusyBox `.bbappend` or configuration fragment to apply your changes.
2. Run `kas shell ../kas/hybrid-demo.yml --command "bitbake busybox"` to rebuild the package.
3. Publish the resulting `.deb` into the local APT repo consumed by ISAR (see the top-level README).
4. Inspect build reuse metrics via `../scripts/hybrid-build-stats.sh`.

