# ISAR Yocto Hybrid Demo (QEMU Focus)

This demo shows how to reuse Debian prebuilt packages with ISAR while selectively rebuilding a handful of components from source using Yocto-style layers. It is tailored for QEMU targets, so you can evaluate the hybrid flow without access to physical hardware.

## Why Hybrid?
- 90%+ of the root filesystem is sourced from ready-made `.deb` packages via ISAR, cutting build time dramatically.
- Only the components that need customization (kernel, container runtime, automotive middleware) are rebuilt from source through `.bbappend` files in `meta-hybrid-demo/recipes-*`.
- No downstream patches to ISAR itself; layering and `SRC_URI` tweaks are sufficient.

## Repository Structure
```
isar-yocto-hybrid-demo/
 ├── kas/
 │    └── hybrid-demo.yml
 ├── meta-hybrid-demo/
 │    ├── README.md
 │    ├── recipes-kernel/
 │    │    └── linux/
 │    │         └── linux-yocto_%.bbappend
 │    └── recipes-core/
 │         └── containerd/
 │              └── containerd_%.bbappend
 ├── scripts/
 │    └── hybrid-build-stats.sh
 └── README.md
```

## Quickstart
1. Install KAS and prerequisites: `pip install kas`.
2. Fetch sources and enter a shell: `kas shell kas/hybrid-demo.yml`.
3. Build the hybrid image: `bitbake isar-image-base`.
4. Boot under QEMU (`docs` has command) to validate.

## Build-Time Stats
Use `scripts/hybrid-build-stats.sh` after a build to print which packages were reused vs. rebuilt and the overall time saved. The script inspects `tmp/log/cooker/qemuarm64` for cache hits/misses.

## Key Configuration Highlights
- `kas/hybrid-demo.yml` enables Debian package reuse via `ISAR_ENABLE_DEB_CACHE` and pins the release to Bookworm.
- The `HYBRID_REBUILD_PN` variable documents which packages you expect to rebuild locally.
- `.bbappend` files live in `meta-hybrid-demo/recipes-kernel/` and `meta-hybrid-demo/recipes-core/`, patching specific components without touching ISAR core classes.

## Next Steps
- Flesh out the pending `.bbappend` files for kernel and containerd.
- Add CI automation (GitLab/Jenkins) to run builds and capture stats automatically.
- Extend scripts to push Yocto-built `.deb` packages into a `reprepro` repository consumed by ISAR.

