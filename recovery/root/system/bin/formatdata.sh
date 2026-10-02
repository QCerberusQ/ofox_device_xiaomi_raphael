#!/system/bin/sh
# TWRP calls this from Format_Data()
# Recreates /data/media/0 to fix MTP issues after format on FBE

grep -q " /data " /proc/mounts || mount /data

mkdir -p /data/media/0
chmod 0770 /data/media /data/media/0

# Force SELinux tags to conform to Android standards (media_rw)
toybox restorecon -R /data/media 2>/dev/null || toybox chcon u:object_r:media_rw_data_file:s0 /data/media /data/media/0

mount -o bind /data/media/0 /sdcard

echo "formatdata.sh: recreated /data/media/0 with correct SELinux contexts" > /dev/kmsg
exit 0
