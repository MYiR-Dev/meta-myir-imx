# Copyright 2019-2021 NXP
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Add packages for AI/ML build"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

ML_NNSTREAMER_PKGS_LIST = " \
    nnshark \
    nnstreamer \
    nnstreamer-armnn \
    nnstreamer-protobuf \
    nnstreamer-python3 \
    nnstreamer-tensorflow-lite \
"

ML_NNSTREAMER_PKGS = ""
ML_NNSTREAMER_PKGS_imxgpu_mx8 = "${ML_NNSTREAMER_PKGS_LIST}"


ML_PKGS            = ""
ML_PKGS_imxgpu_mx8 = " \
    armnn \
    tensorflow-lite \
    tensorflow-lite-vx-delegate \
    ml-security \
    pytorch \
    torchvision \
"
ML_PKGS_mx8ulp = " \
    armnn \
    tensorflow-lite \
    onnxruntime \
    pytorch \
    torchvision \
"
ML_PKGS_remove_mx8mm = "tensorflow-lite-vx-delegate"

ML_DEEPVIEW_PKGS            = ""
ML_DEEPVIEW_PKGS_imxgpu_mx8 = "deepview-rt-examples"
ML_DEEPVIEW_PKGS_mx8mm      = ""

ML_EIQ_PKGS       = ""
ML_EIQ_PKGS_mx8mm = "eiq-apps"
ML_EIQ_PKGS_mx8mp = "eiq-apps"

ML_TVM_PKGS            = ""
ML_TVM_PKGS_imxgpu_mx8 = "tvm"
ML_TVM_PKGS_mx8mm      = ""

RDEPENDS_${PN} = " \
    ${ML_PKGS} \
    ${ML_DEEPVIEW_PKGS} \
    ${ML_EIQ_PKGS} \
    ${ML_TVM_PKGS} \
    ${ML_NNSTREAMER_PKGS} \
"
