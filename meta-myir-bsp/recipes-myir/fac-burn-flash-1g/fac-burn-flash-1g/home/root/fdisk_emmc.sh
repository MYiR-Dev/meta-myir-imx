#!/bin/bash

MMC_info=$(dmesg | grep "MMC")

MMCtest=$(echo "$MMC_info" | cut -d':' -f1 | awk '{print $3}')

MMCNUM=$(echo "$MMCtest" | awk -F'c' '{print $2}')


DEVICE=/dev/mmcblk${MMCNUM}

echo "$DEVICE"

#DEVICE=/dev/mmcblk1	
sgdisk -g "$DEVICE"
(
echo "
x
l
1024
m
n
1
1024
+512KiB
8a7a84a0-8387-40f6-ab41-a8b9a5a60d23
n
2
2048
+512KiB
8a7a84a0-8387-40f6-ab41-a8b9a5a60d23
n
3
3072
+4M
19d5df83-11b0-457b-be2c-7559c13142a5
n
4
11264
+4M
19d5df83-11b0-457b-be2c-7559c13142a5
n
5
19456
+512KiB
3de21764-95bd-54bd-a5c3-4abe786f38a8
n
6
20480
+64M
0fc63daf-8483-4772-8e79-3d69d8477de4
n
7
151552
+183MM
0fc63daf-8483-4772-8e79-3d69d8477de4
n
8
526336
+3G
0fc63daf-8483-4772-8e79-3d69d8477de4
n
9
6817792

0fc63daf-8483-4772-8e79-3d69d8477de4
w
Y
") | gdisk "$DEVICE"




(
echo "
c
1
metadata1
c
2
metadata2
c
3
fip-a
c
4
fip-b
c
5
u-boot-env
c
6
bootfs
c
7
vendorfs
c
8
rootfs
c
9
userfs
w
Y
") | gdisk "$DEVICE"


(
echo "
x
c
1
b19f76dc-51b6-47ff-9fcd-ef229957c4b2
c
2
2234ca05-25e5-442a-95d8-2372adfd1e2f
c
3
4fd84c93-54ef-463f-a7ef-ae25ff887087
c
4
09c54952-d5bf-45af-acee-335303766fb3
c
5
91213942-1460-4da7-8351-936656c5cd99
c
6
95a33ae7-111c-43da-917e-ed818a70dee8
c
7
dff396ae-895e-486d-a5f5-b0b58b1d9cc8
c
8
491f6117-415d-4f53-88c9-6e0de54deac6
c
9
59c76759-7f44-4a90-95ce-2cca2aaa362c
a
6
2

w
Y
") | gdisk "$DEVICE"
