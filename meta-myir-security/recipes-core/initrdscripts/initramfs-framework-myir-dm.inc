# initramfs-framework-myir-dm.inc
# MYIR enhanced dm-verity + overlay initramfs module
#
# Replaces the upstream meta-security dmverity module with an enhanced
# version that adds:
#   - Device wait with configurable timeout
#   - Root hash openssl signature verification
#   - Overlayfs support (/etc, /root, /var)
#
# The module runs at priority 89 (before the rootfs module at 90)
# and handles the full dm-verity + overlay setup.

FILESEXTRAPATHS:prepend := "${THISDIR}/initramfs-framework-myir-dm:"

SRC_URI:append = "\
    file://dmverity-overlay \
"

do_install:append() {
    # dm-verity overlay module (runs at priority 89, before 90-rootfs)
    install -m 0755 ${S}/dmverity-overlay ${D}/init.d/89-dmverity-overlay
}

PACKAGES:append = " initramfs-module-dmverity-overlay"

SUMMARY:initramfs-module-dmverity-overlay = "MYIR enhanced dm-verity + overlay initramfs support"
RDEPENDS:initramfs-module-dmverity-overlay = "${PN}-base cryptsetup util-linux-mount"

# Requires openssl for runtime root hash signature verification
RRECOMMENDS:initramfs-module-dmverity-overlay = "openssl"

FILES:initramfs-module-dmverity-overlay = "/init.d/89-dmverity-overlay"
