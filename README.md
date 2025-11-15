# Yocto Bridge

This project demonstrates how to reuse Debian prebuilt packages with ISAR while selectively rebuilding component(s) from source using Yocto-style. It is tailored for QEMU targets, so you can evaluate the hybrid flow without access to physical hardware.

## Why Hybrid?
- 90%+ of the root filesystem is sourced from ready-made `.deb` packages via ISAR, cutting build time dramatically.
- Only some packages are rebuilt from source through `.bbappend` files.
- No downstream patches to ISAR itself; layering and `SRC_URI` tweaks are sufficient.


## Quickstart
1. Install KAS and prerequisites: `pip install kas`.
3. Build the Yocto component you want to override (e.g. `hybrid-demo-utils`): `./scripts/build-yocto.sh shell  -c "bitbake hybrid-demo-utils"`.
3. Publish the generated `.deb` packages into the local APT repo:\
   `integration/scripts/publish-yocto-debs.sh`
4. Build hybrid container: `docker build -t kas-hy .`.
5. Build the Debian base image with ISAR: `./scripts/build-isar.sh build `.
6. Boot under QEMU to validate.

## Local APT Repository
The `integration/scripts/publish-yocto-debs.sh` helper collects the freshly built Yocto packages, regenerates `integration/local-apt/`, and creates the `Packages`/`Packages.gz` and `Release` metadata. Run it after every Yocto rebuild so the subsequent ISAR build consumes the updated component(s) `.deb`.

## Key Configuration Highlights
- `kas/yocto-bridge.yml` enables Debian package reuse via `ISAR_ENABLE_DEB_CACHE` and pins the release to Bookworm.
- The `HYBRID_REBUILD_PN` variable documents which packages you expect to rebuild locally (currently hybrid-demo-utils).
- `.bbappend` files live in `meta-hybrid-demo/recipes-core/`, patching the hybrid-demo-utils package without touching ISAR core classes.

## Note on meta-hybrid-demo
The `meta-hybrid-demo` directory is a separate GitHub repository. If you're setting up this project fresh, you may want to convert it to a git submodule pointing to its repository.

## Next Steps
- Automate `kas build kas/isar-build.yml` followed by the hybrid Yocto step in CI to prove reuse metrics.
- Extend scripts to push Yocto-built `.deb` packages into a `reprepro` repository consumed by ISAR.

[ISAR](https://github.com/ilbers/isar)

[Yocto Project](https://www.yoctoproject.org/)

[yocto-bridge](https://github.com/osamakader/yocto-bridge)