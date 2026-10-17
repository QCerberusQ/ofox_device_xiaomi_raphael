#!/system/bin/sh
# TWRP calls this from Format_Data() (partitionmanager.cpp:1782).
# /data is mounted here: Wipe() ends with
#     if (Is_Storage && Mount(false) && !Is_FBE)     [partition.cpp:1871]
# and && evaluates left to right, so Mount(false) runs even on FBE -
# only Add_MTP_Storage is skipped. Verified identical in OrangeFox.
grep -q " /data " /proc/mounts || mount /data

mkdir -p /data/media/0
chmod 0770 /data/media /data/media/0
mount -o bind /data/media/0 /sdcard

echo "formatdata.sh: recreated /data/media/0" > /dev/kmsg
exit 0
