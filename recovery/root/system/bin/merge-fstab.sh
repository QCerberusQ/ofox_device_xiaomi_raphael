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

        # Legacy Gapps error fix: MindTheGapps reads ro.boot.dynamic_partitions=true
        # and resolves SYSTEM_BLOCK as ${BLK_PATH}/system under /dev/block/mapper.
        # Fake only that one node - test -b follows the symlink, so blockdev --setrw
        # and mount -o rw both reach the physical partition. Never resetprop here:
        # rewriting a ro. prop deletes and re-adds its trie node, which kills init's
        # property triggers and starves qseecomd (boot logo hang on EFE FBEv1).
        # Deliberately NOT symlinking product/system_ext - leaving them absent keeps
        # PRODUCT_BLOCK empty so the installer copies into the nested /system/product.
        MAPPER=/dev/block/mapper;
        SYSBLK=/dev/block/bootdevice/by-name/system;
        if [ ! -e "$MAPPER/system" ] && [ -b "$SYSBLK" ]; then
            mkdir -p "$MAPPER";
            ln -s "$SYSBLK" "$MAPPER/system";
            echo "merge-fstab: linked $MAPPER/system -> $SYSBLK (legacy ROM)" > /dev/kmsg;
        else
            echo "merge-fstab: WARNING $MAPPER/system exists or $SYSBLK missing - link skipped" > /dev/kmsg;
        fi

        # Testing: confirm the faked node resolves as a block device
        if [ -b "$MAPPER/system" ]; then
            echo "merge-fstab: mapper/system OK [-b passes] super [$(getprop ro.boot.super_partition)]" > /dev/kmsg;
        else
            echo "merge-fstab: WARNING mapper/system does NOT satisfy -b - Gapps will fail" > /dev/kmsg;
        fi

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
