# myir-data-partition: Add /data partition to fstab and create mount point.
#
#   recipes-core/base-files/base-files_%.bbappend
#
# Adds fstab entry for the data partition so it is mounted automatically
# at boot.  The service myir-enc-handler is NOT involved -- this is a
# plain ext4 partition without dm-crypt.
#
# Also appends "cd /data" to /etc/skel/.profile so interactive login
# shells start in the /data partition by default.  Using skel ensures
# this applies to root and any future user accounts.
#
# Triggered by DISTROOVERRIDES ":myir-data-partition" from the bbclass.

do_install:append:myir-data-partition() {
    local auto_option=""
    local modify_fstab="0"

    case "${MYIR_DATA_PARTITION_AUTOMOUNT}" in
        -1)
                modify_fstab="0"
                ;;
        0)
                auto_option="noauto"
                modify_fstab="1"
                ;;
        1)
                auto_option="auto"
                modify_fstab="1"
                ;;
        *)
                bbfatal "Variable MYIR_DATA_PARTITION_AUTOMOUNT is set to an unknown value (${MYIR_DATA_PARTITION_AUTOMOUNT})."
                ;;
    esac

    if [ "${modify_fstab}" = "1" ]; then
        echo "LABEL=${MYIR_DATA_PARTITION_LABEL}  ${MYIR_DATA_PARTITION_MOUNTPOINT}  auto  ${MYIR_DATA_PARTITION_MOUNT_FLAGS},${auto_option}  0  0" >> ${D}/etc/fstab
    fi

    # Auto cd to /data on login (append to skeleton profile)
    echo "" >> ${D}${sysconfdir}/skel/.profile
    echo "# Auto cd to /data partition on login (myir-data-partition)" >> ${D}${sysconfdir}/skel/.profile
    echo "cd /data" >> ${D}${sysconfdir}/skel/.profile
}

pkg_postinst:${PN}:append:myir-data-partition() {
    mkdir -p $D${MYIR_DATA_PARTITION_MOUNTPOINT}
}
