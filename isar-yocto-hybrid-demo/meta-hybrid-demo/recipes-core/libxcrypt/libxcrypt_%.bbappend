FILESEXTRAPATHS:append := ":${THISDIR}/files"

SRC_URI:append = " \
    file://0001-Avoid-given-when-in-BuildCommon.patch \
    file://0002-Avoid-given-when-in-gen-crypt-h.patch \
"
