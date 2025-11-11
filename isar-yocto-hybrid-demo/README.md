# ISAR Yocto Hybrid Demo (QEMU Focus)

This demo shows how to reuse Debian prebuilt packages with ISAR while selectively rebuilding BusyBox from source using Yocto-style layers. It is tailored for QEMU targets, so you can evaluate the hybrid flow without access to physical hardware.

## Why Hybrid?
- 90%+ of the root filesystem is sourced from ready-made `.deb` packages via ISAR, cutting build time dramatically.
- Only BusyBox is rebuilt from source through a `.bbappend` file in `meta-hybrid-demo/recipes-core/`.
- No downstream patches to ISAR itself; layering and `SRC_URI` tweaks are sufficient.

## Repository Structure
```
isar-yocto-hybrid-demo/
 ├── kas/
 │    └── hybrid-demo.yml
 ├── meta-hybrid-demo/
 │    ├── README.md
 │    └── recipes-core/
 │         └── busybox/
 │              └── busybox_%.bbappend
 ├── scripts/
 │    └── hybrid-build-stats.sh
 └── README.md
```

## Quickstart
1. Install KAS and prerequisites: `pip install kas`.
2. Fetch sources for selective rebuilds: `kas shell kas/hybrid-demo.yml`.
3. Build the Yocto component you want to override (currently `busybox`): `bitbake busybox`.
4. Publish the generated `.deb` packages into the local APT repo:\
   `integration/scripts/publish-yocto-debs.sh`
5. Build the Debian base image with ISAR: `kas build kas/isar-build.yml`.
6. Boot under QEMU (`docs` has command) to validate.

## Build-Time Stats
Use `scripts/hybrid-build-stats.sh` after a build to print which packages were reused vs. rebuilt and the overall time saved. The script inspects `tmp/log/cooker/qemuarm64` for cache hits/misses.

## Local APT Repository
The `integration/scripts/publish-yocto-debs.sh` helper collects the freshly built Yocto packages, regenerates `integration/local-apt/`, and creates the `Packages`/`Packages.gz` and `Release` metadata. Run it after every Yocto rebuild so the subsequent ISAR build consumes the updated BusyBox `.deb`.

## Key Configuration Highlights
- `kas/hybrid-demo.yml` enables Debian package reuse via `ISAR_ENABLE_DEB_CACHE` and pins the release to Bookworm.
- The `HYBRID_REBUILD_PN` variable documents which packages you expect to rebuild locally (currently BusyBox).
- `.bbappend` files live in `meta-hybrid-demo/recipes-core/`, patching the BusyBox package without touching ISAR core classes.

## Next Steps
- Extend the `.bbappend` example with real BusyBox patches or feature toggles.
- Add a kernel `.bbappend` once you are ready to rebuild it from Yocto.
- Automate `kas build kas/isar-build.yml` followed by the hybrid Yocto step in CI to prove reuse metrics.
- Extend scripts to push Yocto-built `.deb` packages into a `reprepro` repository consumed by ISAR.

