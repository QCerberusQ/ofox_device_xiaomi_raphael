#!/system/bin/sh

rom_has_dynamic_partitions() {
    local markers="raphael_dynamic_partitions|qti_dynamic_partitions|raphael_dynpart";
    local blk="/dev/block/bootdevice/by-name/system";
    local head;

    if [ ! -e "$blk" ]; then
        echo "merge-fstab: $blk absent - cannot detect layout, assuming dynamic" > /dev/kmsg;
        echo "1";
        return;
    fi

    head="$(dd if="$blk" bs=256k count=1 2>/dev/null | strings)";

    if [ -z "$head" ]; then
        echo "merge-fstab: probe produced no output (dd/strings failed) - assuming dynamic" > /dev/kmsg;
        echo "1";
        return;
    fi

    if echo "$head" | grep -q -E "$markers"; then
        echo "merge-fstab: dynamic markers found - FBEv2" > /dev/kmsg;
        echo "1";
    else
        echo "merge-fstab: probe OK, no dynamic markers - FBEv1" > /dev/kmsg;
        echo "0";
    fi
}

process_fstab_files() {
    if [ "$(rom_has_dynamic_partitions)" = "1" ]; then
        echo "merge-fstab: Loading FBEv2 fstab." > /dev/kmsg;
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
        echo "merge-fstab: Loading FBEv1 fstab." > /dev/kmsg;
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
