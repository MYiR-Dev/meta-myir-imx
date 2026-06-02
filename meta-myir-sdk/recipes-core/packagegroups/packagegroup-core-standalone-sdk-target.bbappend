# Remove staticdev packages that meta-swupdate adds as hard RDEPENDS.
RDEPENDS:packagegroup-core-standalone-sdk-target:remove = "lua-staticdev mtd-utils-staticdev"
