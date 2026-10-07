#!/system/bin/sh
# TWRP calls this from Format_Data() (partitionmanager.cpp:1782).
# /data is mounted here: Wipe() ends with
#     if (Is_Storage && Mount(false) && !Is_FBE)     [partition.cpp:1871]
# and && evaluates left to right, so Mount(false) runs even on FBE -
# only Add_MTP_Storage is skipped. Verified identical in OrangeFox
# (fox_12.1 partition.cpp:1937).
grep -q " /data " /proc/mounts || mount /data

mkdir -p /data/media/0
chmod 0770 /data/media /data/media/0

# Label the per-user dir only. /data/media/.* is media_rw_data_file at every
# API level, but the parent /data/media became media_userdir_file in Android 14
# (sepolicy android-14.0.0_r1 file_contexts:574) - a type absent from this
# recovery's sepolicy, so restorecon -R leaves it unmapped and a recursive
# chcon would stamp the Android 12/13 type onto the parent on newer ROMs.
toybox chcon u:object_r:media_rw_data_file:s0 /data/media/0 2>/dev/null

mount -o bind /data/media/0 /sdcard

echo "formatdata.sh: recreated /data/media/0" > /dev/kmsg
exit 0
