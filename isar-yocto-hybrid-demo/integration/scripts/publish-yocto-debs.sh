#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"
echo "ROOT_DIR: ${ROOT_DIR}"

YOCTO_DEPLOY_DIR=${YOCTO_DEPLOY_DIR:-build/tmp/deploy/deb}
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

mapfile -t DEB_FILES < <(find "${YOCTO_DEPLOY_DIR}" -maxdepth 3 -type f -name "*.deb")
if [[ ${#DEB_FILES[@]} -eq 0 ]]; then
    echo "[error] No .deb packages found under '${YOCTO_DEPLOY_DIR}'." >&2
    exit 1
fi

rm -rf "${LOCAL_APT_DIR}/dists" "${LOCAL_APT_DIR}/pool"
mkdir -p "${LOCAL_APT_DIR}/pool/main"

declare -A ARCH_MAP=()
for deb in "${DEB_FILES[@]}"; do
    arch=$(dpkg-deb --field "${deb}" Architecture)
    ARCH_MAP["${arch}"]=1
    dest_dir="${LOCAL_APT_DIR}/pool/main/${arch}"
    mkdir -p "${dest_dir}"
    cp "${deb}" "${dest_dir}/"
    mkdir -p "${LOCAL_APT_DIR}/pool"
    cp "${deb}" "${LOCAL_APT_DIR}/pool/"
done

cd "${LOCAL_APT_DIR}"

mkdir -p "dists/${CODENAME}/${COMPONENT}"

ARCH_LIST=()
for arch in "${!ARCH_MAP[@]}"; do
    ARCH_LIST+=("${arch}")
    binary_dir="dists/${CODENAME}/${COMPONENT}/binary-${arch}"
    mkdir -p "${binary_dir}"
    apt-ftparchive packages "pool/main/${arch}" > "${binary_dir}/Packages"
    gzip -9fk "${binary_dir}/Packages"
done

IFS=' ' read -r -a ARCH_LIST_SORTED <<< "$(printf '%s
' "${ARCH_LIST[@]}" | sort -u | tr '
' ' ')"

cat > "dists/${CODENAME}/Release" <<EOF
Origin: ${ORIGIN}
Label: ${ORIGIN}
Suite: ${CODENAME}
Codename: ${CODENAME}
Components: ${COMPONENT}
Architectures: ${ARCH_LIST_SORTED[*]}
EOF

echo "[info] Local APT repository updated at '${LOCAL_APT_DIR}'."
