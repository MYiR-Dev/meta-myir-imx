#!/bin/sh
. /etc/board_part_info.conf

echo "EMMC_DEV ${EMMC_DEV}"
echo "SD_DEV ${SD_DEV}"
echo "ROOTFS_A_PART=${ROOTFS_A_PART}"
echo "ROOTFS_B_PART=${ROOTFS_B_PART}"

current_rootfs=""

check_root_part()
{
	cmdline=$(cat /proc/cmdline)
	for arg in $cmdline; do
		case "$arg" in
		root=*)
			current_rootfs=${arg#root=}
			break
			;;
		esac
	done

	# U-Boot uses PARTUUID so the rootfs remains stable if MMC numbering
	# changes. Resolve it back to a concrete mmcblkXpY device for the
	# existing A/B partition-number selection below.
	case "$current_rootfs" in
	PARTUUID=*)
		partuuid=${current_rootfs#PARTUUID=}
		partuuid=${partuuid%%/*}
		part_link="/dev/disk/by-partuuid/${partuuid}"
		if [ -e "$part_link" ]; then
			resolved=$(readlink -f "$part_link" 2>/dev/null || true)
			[ -n "$resolved" ] && current_rootfs=$resolved
		elif command -v blkid >/dev/null 2>&1; then
			resolved=$(blkid -t "PARTUUID=${partuuid}" -o device 2>/dev/null || true)
			[ -n "$resolved" ] && current_rootfs=$resolved
		fi
		;;
	esac

	# findmnt covers systems where udev has not created by-partuuid yet.
	mounted_root=$(findmnt -n -o SOURCE / 2>/dev/null || true)
	case "$mounted_root" in
	/dev/mmcblk*p[0-9]*)
		resolved=$(readlink -f "$mounted_root" 2>/dev/null || true)
		[ -n "$resolved" ] && current_rootfs=$resolved
		;;
	esac

	echo "current_rootfs: $current_rootfs"
}

check_need_replace_env()
{
	if [ -z "$current_rootfs" ]; then
		current_rootfs=$(sed -n 's/.*root=\([^ ]*\).*/\1/p' /proc/cmdline)
	fi

	echo "Current rootfs: $current_rootfs"
	case "$current_rootfs" in
	/dev/mmcblk*p[0-9]*)
		bootdev=${current_rootfs%%p*}
		if ! grep -qF "$bootdev" /etc/fw_env.config; then
			echo "Updating fw_env.config to use $bootdev"
			sed -i "s|^/dev/mmcblk[0-9]*|${bootdev}|" /etc/fw_env.config
			cat /etc/fw_env.config
		else
			echo "Already correct, no change needed."
		fi
		;;
	esac
}

function_on_different_part()
{
	case "$current_rootfs" in
	/dev/mmcblk*p[0-9]*) part_num=${current_rootfs##*p};;
	*)
		echo "Cannot distinguish rootfs partition from '$current_rootfs'"
		exit 1
		;;
	esac

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
		echo "Cannot distinguish rootfs partition number: $part_num"
		exit 1
		;;
	esac

	cat /etc/swupdate/conf.d/99-myir-swupdate.conf
}

check_root_part
check_need_replace_env
function_on_different_part
