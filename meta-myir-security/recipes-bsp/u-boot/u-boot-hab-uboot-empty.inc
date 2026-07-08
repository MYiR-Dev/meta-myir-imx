# u-boot-hab-uboot-empty.inc - Empty stub when HABv4 is disabled
#
# This file is included instead of u-boot-hab-uboot.inc when
# MYIR_HAB_ENABLE != 1 (or the machine is not mx6ull-generic-bsp).
#
# The real u-boot-hab-uboot.inc pulls in heavy dependencies:
#   - xxd-native (for IVT/DCD byte manipulation)
#   - libfaketime-native (for deterministic CSF binaries)
#   - imx-fuses-native (for fuse command generation)
#   - inherit myir-hab (HABv4 variable definitions)
#
# By using this empty stub, i.MX95 (mx9-generic-bsp) builds avoid
# any HAB-related dependency overhead.
#
# This file exists solely to make the conditional include in
# u-boot-imx_%.bbappend syntactically valid.
