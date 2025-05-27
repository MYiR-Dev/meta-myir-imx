#!/bin/sh
	    	
rootfs_name=		
rootfs_start_off=
uuid=
get_rootfs_name(){
	cmd_data=`cat /proc/cmdline`
	for element in ${cmd_data}
	do
		if [ "root=" == "${element%%/*}" ];then
			rootfs_name=${element#*=}
		fi
	done

}


get_rootfs_info(){
	
	if [ -z "${rootfs_name}" ];then
		echo "cannot find rootfs"
		exit 1
	fi
	echo "start get_rootfs_info"
	rootfs_start_off=`partx ${rootfs_name} | sed -n '2p' | awk '{print $2}'`
	uuid=`partx ${rootfs_name} | sed -n '2p' | awk '{print $6}'`

	echo "rootfs_start_off :${rootfs_start_off}  uuid: ${uuid}"
	
}


expand_partition(){
	if [ -z "${rootfs_start_off}" -o -z "${uuid}" ];then
		echo "rootfs or uuid is null: ${rootfs_start_off} :${uuid}"
		exit 1
	fi

	physics_part=${rootfs_name%p*}
	logic_part=${rootfs_name##*p}
	echo "physics_part:${physics_part} logic_part:${logic_part}"
	fdisk ${physics_part} <<EOF
		p
		d
		${logic_part}
		p
		n
		p
		${logic_part}
		${rootfs_start_off}

		p
		w
		q
EOF

	resize2fs ${rootfs_name}

}

get_rootfs_name
get_rootfs_info
expand_partition
