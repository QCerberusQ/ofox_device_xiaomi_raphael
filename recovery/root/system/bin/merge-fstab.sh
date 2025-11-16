#!/system/bin/sh

rom_has_dynamic_partitions() {
    local markers="raphael_dynamic_partitions|qti_dynamic_partitions|raphael_dynpart";

    dd if=/dev/block/by-name/system bs=256k count=1 | strings | grep -q -E $markers > /dev/null
    if [ $? -eq 0 ]; then
        echo "1";
        return;
    fi

    echo "0";
}

process_fstab_files() {
    if [ "$(rom_has_dynamic_partitions)" = "1" ]; then
        echo >> /system/etc/recovery.fstab;
        for p in system system_ext product vendor odm; do
            echo "${p} /${p} ext4 ro,barrier=1 wait,logical" >> /system/etc/recovery.fstab;
            echo "${p} /${p} erofs ro wait,logical" >> /system/etc/recovery.fstab;
        done
        echo >> /system/etc/recovery.fstab;
        cat /system/etc/recovery-fbev2.fstab >> /system/etc/recovery.fstab;
        echo >> /system/etc/twrp.flags;
        cat /system/etc/twrp-dynamic.flags >> /system/etc/twrp.flags;
    else
        echo >> /system/etc/recovery.fstab;
        cat /system/etc/recovery-fbev1.fstab >> /system/etc/recovery.fstab;
        echo >> /system/etc/twrp.flags;
        cat /system/etc/twrp-legacy.flags >> /system/etc/twrp.flags;
    fi
}

do_cleanup() {
    rm -f /system/etc/recovery-*.fstab;
    rm -f /system/etc/twrp-*.flags;
}

# Run the script
process_fstab_files;
do_cleanup;
exit 0;
