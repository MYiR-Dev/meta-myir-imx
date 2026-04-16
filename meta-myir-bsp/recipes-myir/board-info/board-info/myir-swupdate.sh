#!/bin/sh
. /etc/board_part_info.conf
echo EMMC_DEV ${EMMC_DEV}
echo SD_DEV ${SD_DEV}
echo ROOTFS_A_PART=${ROOTFS_A_PART}
echo ROOTFS_B_PART=${ROOTFS_B_PART}

current_rootfs=""

check_root_part_cmdline()
{
	cmdline=`cat /proc/cmdline`
	for i  in $cmdline
	do
		if [[ `echo $i | grep "root="` != "" ]];then
			current_rootfs=${i##*/}
			echo "current_rootfs: $current_rootfs"
		fi
	done


}

check_need_replace_env() {
    local current_rootfs="$1" 

    if [[ -z "$current_rootfs" ]]; then
        current_rootfs=$(sed -n 's/.*root=\([^ ]*\).*/\1/p' /proc/cmdline)
    fi

    echo "Current rootfs: $current_rootfs"

    if [[ $current_rootfs =~ ^/dev/mmcblk ]]; then
        bootdev=${current_rootfs%%p*}

        if ! grep -qF "$bootdev" /etc/fw_env.config; then
            echo "Updating fw_env.config to use $bootdev"
            sed -i "s|^/dev/mmcblk[0-9]*|${bootdev}|" /etc/fw_env.config
            echo "New content:"
            cat /etc/fw_env.config
        else
            echo "Already correct, no change needed."
        fi
    fi
}


function_on_different_part()
{
	part_num=${current_rootfs##*p}

	mkdir -p /etc/swupdate/conf.d

	case "$part_num" in
        ${ROOTFS_A_PART})
		echo "rootfs A part"
		cat > /etc/swupdate/conf.d/99-myir-swupdate.conf << 'EOF'
SWUPDATE_ARGS="-v -d -uhttp://192.168.40.241/myir_1.0_LF_v6.12.49_2.1.0_singlecopy_emmc_image_20260415_sign.swu -e stable,dualA_to_dualB"
SWUPDATE_WEBSERVER_ARGS=""
EOF
        ;;
        ${ROOTFS_B_PART})
                echo "rootfs B part"
		cat > /etc/swupdate/conf.d/99-myir-swupdate.conf << 'EOF'
SWUPDATE_ARGS="-v -d -uhttp://192.168.40.241/myir_1.0_LF_v6.12.49_2.1.0_singlecopy_emmc_image_20260415_sign.swu -e stable,dualB_to_dualA"
SWUPDATE_WEBSERVER_ARGS=""
EOF
        ;;
        *)
                echo "con not distinguish part"
                exit 1
        esac

	cat /etc/swupdate/conf.d/99-myir-swupdate.conf
}


check_root_part_cmdline

check_need_replace_env

function_on_different_part

