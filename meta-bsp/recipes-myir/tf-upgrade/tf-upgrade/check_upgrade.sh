#!/bin/sh
# function: TF card detect and auto upgrade script 
# auth: coin.du@myirtech.com
# company MYIR
# date 2021-04-02


BOARD_MANUFACTURER=MYIR
BOARD_VERSION=1.0
BOARD_INFO_PATH=/upgrade/info.txt
BOARD_HAVE_INFO=1
CHECK_FILE_PATH=/run/media/mmcblk1p2/upgrade/info.txt
UPGRADE_PART=mmcblk2


read_board_info(){
    if [  -f $BOARD_INFO_PATH ];then
        if [  `cat $BOARD_INFO_PATH | grep MANUFACTURER | wc -c ` -gt 0 ];then
            BOARD_MANUFACTURER=`cat $BOARD_INFO_PATH | grep MANUFACTURER | awk -F[=] '{print $2}'`
        fi
        
        if [  `cat $BOARD_INFO_PATH | grep VERSION | wc -c ` -gt 0 ];then
            BOARD_VERSION=`cat $BOARD_INFO_PATH | grep VERSION | awk -F[=] '{print $2}'`
        fi

    else
        BOARD_HAVE_INFO=0
    fi
    echo "BOARD_MANUFACTURER=$BOARD_MANUFACTURER"
    echo "BOARD_VERSION=$BOARD_VERSION"
}
need_upgrade(){
    dd if=/dev/zero of=/dev/$UPGRADE_PART bs=1M count=5
    mmc bootpart enable 0 1 /dev/$UPGRADE_PART
    echo "UPGRADE REBOOT"
    reboot
}

check_upgrade_info(){

    UPGRADE_INFO_MANUFACTURER=
    UPGRADE_INFO_BOARD_VERSION=
    UPGRADE_INFO_FLAG=0
    
    
    if [  `cat $CHECK_FILE_PATH | grep MANUFACTURER | wc -c ` -gt 0 ];then
        UPGRADE_INFO_MANUFACTURER=`cat $CHECK_FILE_PATH | grep MANUFACTURER | awk -F[=] '{print $2}'`
    fi
    if [  `cat $CHECK_FILE_PATH | grep VERSION | wc -c ` -gt 0 ];then
        UPGRADE_INFO_BOARD_VERSION=`cat $CHECK_FILE_PATH | grep VERSION | awk -F[=] '{print $2}'`
    fi
    if [  `cat $CHECK_FILE_PATH | grep FLAG | wc -c ` -gt 0 ];then
        UPGRADE_INFO_FLAG=`cat $CHECK_FILE_PATH | grep FLAG | awk -F[=] '{print $2}'`
    fi
    echo "UPGRADE_INFO_MANUFACTURER = $UPGRADE_INFO_MANUFACTURER"
    echo "UPGRADE_INFO_BOARD_VERSION = $UPGRADE_INFO_BOARD_VERSION"
    echo "UPGRADE_INFO_FLAG = $UPGRADE_INFO_FLAG"

    if [ $BOARD_HAVE_INFO -eq 0  ];then
        echo "BOARD LACK INFO NEED FORCE UPGRADE"
        need_upgrade
    fi

    if [ "X"$UPGRADE_INFO_MANUFACTURER == "X"$BOARD_MANUFACTURER ];then

        echo "MANUFACTURER is equal"
        BOARD_VERSION_MAJOR=${BOARD_VERSION%.*}
        BOARD_VERSION_MINOR=${BOARD_VERSION#*.}

        UPGRADE_VERSION_MAJOR=${UPGRADE_INFO_BOARD_VERSION%.*}
        UPGRADE_VERSION_MINOR=${UPGRADE_INFO_BOARD_VERSION#*.}

        if [ $UPGRADE_VERSION_MAJOR -gt $BOARD_VERSION_MAJOR ];then
            echo "UPGRADE_VERSION_MAJOR > BOARD_VERSION_MAJOR"
            need_upgrade
        elif [ $UPGRADE_VERSION_MAJOR -eq $BOARD_VERSION_MAJOR ] ;then
            echo "UPGRADE_VERSION_MAJOR == BOARD_VERSION_MAJOR"
            if [ $UPGRADE_VERSION_MINOR -gt $BOARD_VERSION_MINOR ];then
                echo "UPGRADE_VERSION_MINOR > BOARD_VERSION_MINOR"
                need_upgrade
            elif [ $UPGRADE_VERSION_MINOR -lt $BOARD_VERSION_MINOR -a $UPGRADE_INFO_FLAG -eq 1 ];then
                echo "UPGRADE_VERSION_MINOR < BOARD_VERSION_MINOR"
                need_upgrade
            fi
        elif [ $UPGRADE_VERSION_MAJOR -lt $BOARD_VERSION_MAJOR -a  $UPGRADE_INFO_FLAG -eq 1 ];then
            echo "UPGRADE_VERSION_MAJOR < BOARD_VERSION_MAJOR"
            need_upgrade
        fi
        

    fi

}

detect_tf_info(){
    while [ 1 ];do

        
        if [ -f $CHECK_FILE_PATH ];then
            
            check_upgrade_info 
        fi

        sleep 3
    done
}




read_board_info 
detect_tf_info
