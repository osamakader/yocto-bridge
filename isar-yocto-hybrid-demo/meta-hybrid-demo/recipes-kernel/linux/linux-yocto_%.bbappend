# Example: pull kernel sources from a custom fork and add an RT config fragment

SRC_URI = "git://git.yoctoproject.org/linux-yocto.git;branch=stable/v5.15/preempt-rt;protocol=https"
SRCREV = "9e6d292cbf420fc9183cd741fdda2c78ff94c17e"

FILESEXTRAPATHS:append := ":${THISDIR}/linux-yocto/files"

KERNEL_FEATURES:append = " \
    features/yocto/rt.cfg \
    cfg/rt-kernel.cfg \
"

# Enable deterministic timestamping for reproducibility
KBUILD_BUILD_TIMESTAMP = "2025-01-01T00:00:00"

