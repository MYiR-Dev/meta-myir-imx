#!/bin/sh

# systemd service logs to journal only; redirect stdout/stderr to serial console
for _tty in /dev/console /dev/ttymxc0; do
	if [ -c "$_tty" ] && [ -w "$_tty" ]; then
		exec >"$_tty" 2>&1
		break
	fi
done
unset _tty

## nand partition 
part_uboot=0
part_env=1
part_kernel=2
part_dtb=3
part_rootfs=4
part_data=5

LED_PID=""

STEP=0
TOTAL_STEPS=6

mfg_path=/root/mfg-images

get_led(){

	if echo ${ledname} | egrep -q '^[0-9]+$'; then
		echo "LED is GPIO"
		echo ${ledname} > /sys/class/gpio/export
		echo "out" > /sys/class/gpio/gpio${ledname}/direction
		echo 1 > /sys/class/gpio/gpio${ledname}/value
		LED_GPIO_NAME="GPIO"
	else
		LED_GPIO_NAME="NAME"
		echo heartbeat > /sys/class/leds/${ledname}/trigger
	fi
}


update_start(){

	echo "Update starting..."

	echo "Update starting..."
	if [ "${LED_GPIO_NAME}" == "NAME" ];then
		echo heartbeat > /sys/class/leds/${ledname}/trigger
		while true;do
			echo "Updating..."
			sleep 3
		done
	elif [ "${LED_GPIO_NAME}" == "GPIO" ];then

		while true;do
			echo "Updating..."
			echo 1 > /sys/class/gpio/gpio${ledname}/value
			sleep 2
			echo "Updating..."
			echo 0 > /sys/class/gpio/gpio${ledname}/value
			sleep 2
		done
	fi
}



update_fail()
{
	kill $LED_PID

	if [ "${LED_GPIO_NAME}" == "NAME" ];then
		echo none > /sys/class/leds/${ledname}/trigger
		echo 0 > /sys/class/leds/${ledname}/brightness
	elif [ "${LED_GPIO_NAME}" == "GPIO" ];then
		echo 1 > /sys/class/gpio/gpio${ledname}/value
	fi

	if [ x"$1" == "no_loop" ];then
		echo "Update failed..."
	else
		while true;do
			echo "Update failed..."
			sleep 1
			echo "Update failed..."
			sleep 1
		done
	fi
}

update_success()
{
	kill $LED_PID
	if [ "${LED_GPIO_NAME}" == "NAME" ];then
		echo none > /sys/class/leds/${ledname}/trigger
		echo 1 > /sys/class/leds/${ledname}/brightness
	elif [ "${LED_GPIO_NAME}" == "GPIO" ];then
		echo 0 > /sys/class/gpio/gpio${ledname}/value
	fi

	echo "************************************************"
	echo "********** System update successfully **********"
	echo "********** System update successfully **********"
	echo "********** System update successfully **********"
	echo "************************************************"
	echo
}

check_file()
{
	if [ ! -s $1 ];then
		echo "invalid imagefile $1"
		echo
		update_fail
	fi
}

cmd_check()
{
	if [ $1 -ne 0 ];then
		echo "$2 failed!"
		echo
		update_fail
	else
		echo "$2 okay!"
	fi
}

flashing_uboot(){
	flash_erase /dev/mtd${part_uboot} 0 0 && kobs-ng init -x -v ${uboot}
	cmd_check $? "Flash uboot  "
}

flashing_erase_env(){
	flash_erase /dev/mtd${part_env} 0 0
	cmd_check $? "Clean env"
}

flashing_dtb(){
	flash_erase /dev/mtd${part_dtb} 0 0 && nandwrite -p /dev/mtd${part_dtb} -p ${dtb}
	cmd_check $? "Flash dtb file"
}

flashing_kernel(){
	flash_erase /dev/mtd${part_kernel} 0 0 && nandwrite -p /dev/mtd${part_kernel} -p ${kernel}
	cmd_check $? "Flash kernel file"
}

flashing_rootfs(){
	ubidetach -m ${part_rootfs} 2>/dev/null

	## erase
	flash_erase /dev/mtd${part_rootfs} 0 0
	cmd_check $? "erase /dev/mtd${part_rootfs}"

	## flashing
	typefile=${rootfs##*.}
	echo "typefile:$typefile"
	if [ x"$typefile" = x"ubi" ]
	then
		nandwrite -q /dev/mtd${part_rootfs} ${rootfs}
		ubiattach -m ${part_rootfs}
		cmd_check $? "attach /dev/mtd${part_rootfs}"

		vol_name=$(cat /sys/class/ubi/ubi0_0/name 2>/dev/null)
		if [ "$vol_name" != "rootfs" ]; then
			ubirename /dev/ubi0 "$vol_name" rootfs
			cmd_check $? "rename ubi volume to rootfs"
		fi
	else
		ubiformat /dev/mtd${part_rootfs}
		cmd_check $? "format /dev/mtd${part_rootfs}"

		ubiattach /dev/ubi_ctrl -m ${part_rootfs}
		cmd_check $? "attach /dev/mtd${part_rootfs}"

		ubimkvol /dev/ubi0 -Nrootfs -m
		cmd_check $? "make volume /dev/mtd${part_rootfs}"
		
		mkdir -p /run/media/mtd${part_rootfs} && mount -t ubifs ubi0:rootfs /run/media/mtd${part_rootfs}
		cmd_check $? "mount /dev/mtd${part_rootfs}"

		tar xf ${rootfs} -C /run/media/mtd${part_rootfs}
		cmd_check $? "tar /dev/mtd${part_rootfs}"
		
		sync
		sync
		sync
		umount /run/media/mtd${part_rootfs}
	fi
}


########################
## start update system

# check mfg-images file 
if [ -f ${mfg_path}/myd-y6ull-14x14-nand-256d-Manifest ]
then
    . ${mfg_path}/myd-y6ull-14x14-nand-256d-Manifest
else
    echo "Can not find file ${mfg_path}/myd-y6ull-14x14-nand-256d-Manifest"
	update_fail "no_loop"
    exit 1
fi

get_led
update_start &
LED_PID=$!

uboot=${mfg_path}/${ubootfile}
kernel=${mfg_path}/${kernelfile}
dtb=${mfg_path}/${dtbfilenand}
rootfs=${mfg_path}/${rootfsfile}

## check boot file 
let STEP=STEP+1
echo -n "[ ${STEP} / ${TOTAL_STEPS} ] Check image files in $mfg_path ... "
check_file $uboot
check_file $kernel
check_file $dtb
check_file $rootfs
echo "OK"                                                                                                                                                                                                            

let STEP=STEP+1
echo -n "[ ${STEP} / ${TOTAL_STEPS} ] flashing uboot  ... "
flashing_uboot

let STEP=STEP+1
echo -n "[ ${STEP} / ${TOTAL_STEPS} ] erase  env  ... "
flashing_erase_env

let STEP=STEP+1
echo -n "[ ${STEP} / ${TOTAL_STEPS} ] flashing kernel  ... "
flashing_kernel

let STEP=STEP+1
echo -n "[ ${STEP} / ${TOTAL_STEPS} ] flashing dtb  ... "
flashing_dtb

let STEP=STEP+1
echo -n "[ ${STEP} / ${TOTAL_STEPS} ] flashing rootfs  ... "
flashing_rootfs

update_success

exit
