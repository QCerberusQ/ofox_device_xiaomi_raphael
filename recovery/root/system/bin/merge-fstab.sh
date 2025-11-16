#!/system/bin/sh

if dd if=/dev/block/by-name/system bs=256k count=1 | strings | grep -q -E "raphael_dynamic_partitions|qti_dynamic_partitions|raphael_dynpart" > /dev/null; then
    echo >> /system/etc/recovery.fstab
    for p in system system_ext product vendor odm; do
        echo "${p} /${p} ext4 ro,barrier=1 wait,logical" >> /system/etc/recovery.fstab
        echo "${p} /${p} erofs ro wait,logical" >> /system/etc/recovery.fstab
    done
    echo >> /system/etc/recovery.fstab
    cat /system/etc/recovery.fstab.fbev2 >> /system/etc/recovery.fstab
    echo >> /system/etc/twrp.flags
    cat /system/etc/twrp.flags.dynamic >> /system/etc/twrp.flags
else
    echo >> /system/etc/recovery.fstab
    cat /system/etc/recovery.fstab.fbev1 >> /system/etc/recovery.fstab
    echo >> /system/etc/twrp.flags
    cat /system/etc/twrp.flags.legacy >> /system/etc/twrp.flags
fi
