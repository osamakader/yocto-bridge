# Example: enable cgroup v2 support and inject custom version string

EXTRA_OEMAKE:append = " BUILDTAGS='seccomp apparmor cni'"

do_configure:append() {
    echo "# hybrid demo build" >> config/config.go
}

PV = "${PV}+hybrid"

