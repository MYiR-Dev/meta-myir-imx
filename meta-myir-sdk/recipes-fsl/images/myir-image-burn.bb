# Copyright 2018-2026 MYIR
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This is the basic core image with minimal tests"

inherit core-image

IMAGE_FEATURES += " \
    tools-profile \
    tools-sdk \
    splash \
    nfs-client \
    tools-debug \
    ssh-server-openssh \
    tools-testapps \
    hwcodecs \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
"

SDKIMAGE_FEATURES:append = " \
    staticdev-pkgs \
"

IMAGE_INSTALL += " \
    tcpdump \
    u-boot-imx-env \
    libubootenv \
    libubootenv-bin \
    uboot-env \
    iperf3 \
    myir-fac-burn \
    mmc-utils \
    board-info \
"
IMAGE_INSTALL:remove = "udev-extraconf"

export IMAGE_BASENAME = "myir-image-burn"
