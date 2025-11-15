#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"
echo "ROOT_DIR: ${ROOT_DIR}"

# Try both build-yocto and .build-yocto as defaults
if [[ -z "${YOCTO_DEPLOY_DIR:-}" ]]; then
    if [[ -d "build-yocto/build/tmp/deploy/deb" ]]; then
        YOCTO_DEPLOY_DIR="build-yocto/build/tmp/deploy/deb"
    elif [[ -d ".build-yocto/build/tmp/deploy/deb" ]]; then
        YOCTO_DEPLOY_DIR=".build-yocto/build/tmp/deploy/deb"
    else
        YOCTO_DEPLOY_DIR="build-yocto/build/tmp/deploy/deb"
    fi
fi

LOCAL_APT_DIR=${LOCAL_APT_DIR:-integration/local-apt}
CODENAME=${CODENAME:-bookworm}
COMPONENT=${COMPONENT:-main}
ORIGIN=${ORIGIN:-hybrid-local}

if ! command -v apt-ftparchive >/dev/null 2>&1; then
    echo "[error] apt-ftparchive is required but not installed" >&2
    exit 1
fi

if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "[error] dpkg-deb is required but not installed" >&2
    exit 1
fi

if [[ ! -d "${YOCTO_DEPLOY_DIR}" ]]; then
    echo "[error] Yocto deploy directory '${YOCTO_DEPLOY_DIR}' not found." >&2
    exit 1
fi

echo "[info] Using YOCTO_DEPLOY_DIR: ${YOCTO_DEPLOY_DIR}"

mapfile -t DEB_FILES < <(find "${YOCTO_DEPLOY_DIR}" -maxdepth 3 -type f -name "*.deb")
if [[ ${#DEB_FILES[@]} -eq 0 ]]; then
    echo "[error] No .deb packages found under '${YOCTO_DEPLOY_DIR}'." >&2
    exit 1
fi

echo "[info] Found ${#DEB_FILES[@]} .deb package(s)"

rm -rf "${LOCAL_APT_DIR}/dists" "${LOCAL_APT_DIR}/pool"
mkdir -p "${LOCAL_APT_DIR}/pool/main"

declare -A ARCH_MAP=()

# Copy packages to pool (only original filenames - apt-ftparchive handles URL encoding)
for deb in "${DEB_FILES[@]}"; do
    arch=$(dpkg-deb --field "${deb}" Architecture)
    ARCH_MAP["${arch}"]=1
    dest_dir="${LOCAL_APT_DIR}/pool/main/${arch}"
    mkdir -p "${dest_dir}"
    base_name="$(basename "${deb}")"
    
    # Copy only the original file - apt-ftparchive will handle URL encoding in Packages file
    # Don't create encoded filenames as that causes duplicate entries in Packages
    cp "${deb}" "${dest_dir}/${base_name}"
done

cd "${LOCAL_APT_DIR}"

mkdir -p "dists/${CODENAME}/${COMPONENT}"

ARCH_LIST=()
for arch in "${!ARCH_MAP[@]}"; do
    ARCH_LIST+=("${arch}")
    binary_dir="dists/${CODENAME}/${COMPONENT}/binary-${arch}"
    mkdir -p "${binary_dir}"
    echo "[info] Generating Packages file for ${arch} from pool/main/${arch}..."
    # Use apt-ftparchive to generate Packages file - it handles URL encoding in Filename field automatically
    apt-ftparchive packages "pool/main/${arch}" > "${binary_dir}/Packages"
    gzip -9fk "${binary_dir}/Packages"
    pkg_count=$(grep -c "^Package:" "${binary_dir}/Packages" || echo "0")
    echo "[info] Generated Packages file with ${pkg_count} entries"
done

IFS=' ' read -r -a ARCH_LIST_SORTED <<< "$(printf '%s
' "${ARCH_LIST[@]}" | sort -u | tr '
' ' ')"

# Generate Release file with proper Date and Hash fields
cat > "dists/${CODENAME}/Release" <<EOF
Origin: ${ORIGIN}
Label: ${ORIGIN}
Suite: ${CODENAME}
Codename: ${CODENAME}
Date: $(date -u +"%a, %d %b %Y %H:%M:%S UTC")
Components: ${COMPONENT}
Architectures: ${ARCH_LIST_SORTED[*]}
EOF

# Collect all hashes first
MD5_HASHES=()
SHA1_HASHES=()
SHA256_HASHES=()

for arch in "${ARCH_LIST[@]}"; do
    binary_dir="dists/${CODENAME}/${COMPONENT}/binary-${arch}"
    if [ -f "${binary_dir}/Packages" ]; then
        md5=$(md5sum "${binary_dir}/Packages" | cut -d' ' -f1)
        sha1=$(sha1sum "${binary_dir}/Packages" | cut -d' ' -f1)
        sha256=$(sha256sum "${binary_dir}/Packages" | cut -d' ' -f1)
        size=$(stat -c%s "${binary_dir}/Packages")
        MD5_HASHES+=(" ${md5} ${size} ${COMPONENT}/binary-${arch}/Packages")
        SHA1_HASHES+=(" ${sha1} ${size} ${COMPONENT}/binary-${arch}/Packages")
        SHA256_HASHES+=(" ${sha256} ${size} ${COMPONENT}/binary-${arch}/Packages")
    fi
    if [ -f "${binary_dir}/Packages.gz" ]; then
        md5=$(md5sum "${binary_dir}/Packages.gz" | cut -d' ' -f1)
        sha1=$(sha1sum "${binary_dir}/Packages.gz" | cut -d' ' -f1)
        sha256=$(sha256sum "${binary_dir}/Packages.gz" | cut -d' ' -f1)
        size=$(stat -c%s "${binary_dir}/Packages.gz")
        MD5_HASHES+=(" ${md5} ${size} ${COMPONENT}/binary-${arch}/Packages.gz")
        SHA1_HASHES+=(" ${sha1} ${size} ${COMPONENT}/binary-${arch}/Packages.gz")
        SHA256_HASHES+=(" ${sha256} ${size} ${COMPONENT}/binary-${arch}/Packages.gz")
    fi
done

# Write all hashes in correct format
cat >> "dists/${CODENAME}/Release" <<EOF
MD5Sum:
$(printf '%s\n' "${MD5_HASHES[@]}")
SHA1:
$(printf '%s\n' "${SHA1_HASHES[@]}")
SHA256:
$(printf '%s\n' "${SHA256_HASHES[@]}")
EOF

echo "[info] Local APT repository updated at '${LOCAL_APT_DIR}'."
echo "[info] Release file date: $(date -u +"%a, %d %b %Y %H:%M:%S UTC")"
echo "[info] To clear APT cache in ISAR build, the Release file timestamp has been updated."
