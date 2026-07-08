# libfaketime_%.bbappend
# Add native build support for HABv4 deterministic CSF generation.
# The original recipe in meta-openembedded lacks BBCLASSEXTEND,
# but meta-myir-security's u-boot-hab-uboot.inc depends on libfaketime-native
# for HABv4 secure boot signing (i.MX6ULL).
BBCLASSEXTEND = "native"
