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
        case ${current_rootfs:0-1} in 
        ${ROOTFS_A_PART})
                echo "rootfs A part"
		fw_setenv swu_mode 0
		fw_setenv boot_limit 3
		fw_setenv mmcbootpart ${ROOTFS_A_PART}
		fw_setenv mmcbootpart_back ${ROOTFS_B_PART}
		echo "SWUPDATE_ARGS=\"-v -d -uhttp://192.168.1.20/MYD-LMX9X-IMAGE/myd-lmx9x.swu -e stable,main\"" > /etc/myir-swupdate.cfg
        ;;
        ${ROOTFS_B_PART})
                echo "rootfs B part" 
		fw_setenv swu_mode 0
		fw_setenv boot_limit 3
		fw_setenv mmcbootpart ${ROOTFS_B_PART}
		fw_setenv mmcbootpart_back ${ROOTFS_A_PART}
		echo "SWUPDATE_ARGS=\"-v -d -uhttp://192.168.1.20/MYD-LMX9X-IMAGE/myd-lmx9x.swu -e stable,alt\"" > /etc/myir-swupdate.cfg
        ;;
        *)
                echo "con not distinguish part"
                exit 1
        esac
}


check_root_part_cmdline

check_need_replace_env

function_on_different_part


source /etc/myir-swupdate.cfg
swupdate $SWUPDATE_ARGS
