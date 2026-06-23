# linux-imx_%.bbappend
# Kernel security configuration for MYIR i.MX95
#
# Uses modular linux-sec-features.inc to conditionally include:
#   - dm-verity.cfg       (when myir-dmverity is in OVERRIDES)
#   - dm-crypt.cfg + CAAM (when myir-encrypted is in OVERRIDES)
#
# FILESEXTRAPATHS is set in linux-sec-features.inc, not here.
#

require linux-sec-features.inc
