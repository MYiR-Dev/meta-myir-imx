# Copyright 2018-2026 MYIR
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This is the basic core image with minimal tests. \
This image contains everything used to test i.MX machines including GUI, \
demos and lots of applications. This creates a very large image, not \
suitable for production."
LICENSE = "MIT"

inherit core-image

### WARNING: This image is NOT suitable for production use and is intended
###          to provide a way for users to reproduce the image used during
###          the validation process of i.MX BSP releases.

## Select Image Features
IMAGE_FEATURES += " \
    tools-profile \
    tools-sdk \
    package-management \
    splash \
    nfs-client \
    tools-debug \
    ssh-server-openssh \
    hwcodecs \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston','', d)} \
"

SDKIMAGE_FEATURES:append = " \
    staticdev-pkgs \
"

CLINFO              ?= ""
CLINFO:imxgpu        = "clinfo"
CLINFO:mx8mm-nxp-bsp = ""
CLINFO:mx7-nxp-bsp   = ""

V2X_PKGS = ""
V2X_PKGS:mx8dxl-nxp-bsp = "packagegroup-imx-v2x"

DOCKER            ?= ""
DOCKER:mx8-nxp-bsp = "docker"
DOCKER:mx9-nxp-bsp = "docker"

SWUPDATE          ?= ""
SWUPDATE:mx9-nxp-bsp = "lua swupdate swupdate-www swupdate-progress swupdate-client swupdate-tools-ipc systemd-swusys json-c"

OPTEE_TEST          ?= ""
OPTEE_TEST:mx9-nxp-bsp = "lvm2 optee-test python3-cryptography optee-examples openssl"

OPTEE_TEST:mx6ull-nxp-bsp = "lvm2 optee-test optee-client python3-cryptography optee-examples openssl"

EEPROM_PNSN      ?= ""
EEPROM_PNSN:mx95-nxp-bsp  = "eeprom-pnsn"

G2D_SAMPLES              = ""
G2D_SAMPLES:imxgpu2d     = "imx-g2d-samples"
G2D_SAMPLES:mx93-nxp-bsp = "imx-g2d-samples"
G2D_SAMPLES:mx943-nxp-bsp = "imx-g2d-samples"

# ===================================================================
# Machine-aware package split
#
# Three tiers:
#   COMMON packages for ALL supported machines (mx6ull, mx93, mx95)
#   MX9    packages for mx93/mx95 only (GPU, ISP, WiFi/BT, HMI)
#   MX6ULL packages specific to mx6ull (currently empty; extension point)
#
# BitBake override syntax (:append:override) is used rather than
# bb.utils.contains('OVERRIDES', ...) because OVERRIDES uses colons
# as separators, but bb.utils.contains() splits on whitespace.
#
# Package list verified against original multimedia.bb (flat list):
#   backup_6ull_port_20260627_154937/myir-image-multimedia.bb.v5_before_cleanup
# For mx93/mx95: COMMON + MX9 matches original flat list exactly.
# ===================================================================

# Tier 1: Common packages for all supported machines
# bridge-utils & net-tools: in the original flat list they were installed for
#   all machines. Moved here to COMMON to preserve mx93/mx95 backward compat.
CORE_IMAGE_EXTRA_INSTALL_COMMON = " \
    packagegroup-imx-core-tools \
    packagegroup-imx-security \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    firmwared \
    curl \
    v4l-utils \
    tcpdump \
    u-boot-imx-env \
    libubootenv \
    libubootenv-bin \
    uboot-env \
    tzdata \
    tslib \
    tslib-calibrate \
    tslib-conf \
    tslib-uinput \
    tslib-tests \
    iperf3 \
    alsa-utils \
    serialcheck \
    libdrm-tests \
    sqlite3 \
    hostapd \
    autorun-script \
    ppp \
    ppp-quectel \
    myir-test-function \
    myir-lvgl \
    myir-tools \
    board-info \
    libmodbus \
    bridge-utils \
    net-tools \
    vim \
"

# Tier 2: mx93/mx95 additional packages (NOT installed on mx6ull)
#   GPU/ISP:    packagegroup-fsl-tools-gpu, -gpu-external, -testapps, -benchmark,
#               packagegroup-imx-isp
#   WiFi/BT:    nxp-bt-init, aw-xm729, quectel-cm, auto-wifi
#   Display:    myir-regulatory
#   Qt6/HMI:    myir-hmi
#   Tools:      packagegroup-core-full-cmdline, -tools-bluetooth, -fsl-tools-audio
CORE_IMAGE_EXTRA_INSTALL_MX9 = " \
    packagegroup-core-full-cmdline \
    packagegroup-tools-bluetooth \
    packagegroup-fsl-tools-audio \
    packagegroup-fsl-tools-gpu \
    packagegroup-fsl-tools-gpu-external \
    packagegroup-fsl-tools-testapps \
    packagegroup-fsl-tools-benchmark \
    packagegroup-imx-isp \
    auto-wifi \
    nxp-bt-init \
    aw-xm729 \
    quectel-cm \
    myir-regulatory \
    myir-hmi \
"

# Tier 3: mx6ull additional packages currently empty
# (was: bridge-utils net-tools moved to COMMON for backward compat)
# Extend here for future 6ul-specific additions.
CORE_IMAGE_EXTRA_INSTALL_MX6ULL = ""

# Assemble base: COMMON packages for all machines
CORE_IMAGE_EXTRA_INSTALL = " \
    ${CORE_IMAGE_EXTRA_INSTALL_COMMON} \
"

# Machine-specific additions via Override syntax (standard BitBake idiom)
# NOTE: mx9-nxp-bsp covers both mx93-nxp-bsp and mx95-nxp-bsp
CORE_IMAGE_EXTRA_INSTALL:append:mx9-nxp-bsp = " ${CORE_IMAGE_EXTRA_INSTALL_MX9}"
CORE_IMAGE_EXTRA_INSTALL:append:mx6ull-nxp-bsp = " ${CORE_IMAGE_EXTRA_INSTALL_MX6ULL}"

# Dynamic extras (no machine condition needed each var has its own overrides)
CORE_IMAGE_EXTRA_INSTALL:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'crrm', 'imx-secure-enclave-crrm', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11 wayland', 'weston-xwayland xterm', '', d)} \
    ${V2X_PKGS} \
    ${CLINFO} \
    ${SWUPDATE} \
    ${OPTEE_TEST} \
    ${EEPROM_PNSN} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'hailo', 'hailo-pci hailo-firmware packagegroup-hailo-hailort', '', d)} \
"
