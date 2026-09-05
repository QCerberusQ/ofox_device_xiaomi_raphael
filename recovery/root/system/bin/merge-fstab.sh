#!/system/bin/sh

rom_has_dynamic_partitions() {
    local blk="/dev/block/bootdevice/by-name/system";
    local off;

    # Legacy is the safe default: a legacy fstab on a dynamic ROM fails loudly at
    # mount time and never touches keys, whereas a dynamic fstab on a legacy ROM
    # mounts far enough to look alive and then regenerates the FBE keys.
    if [ ! -e "$blk" ]; then
        echo "merge-fstab: $blk absent - assuming legacy (FBEv1)" > /dev/kmsg;
        echo "0";
        return;
    fi

    # liblp LP_METADATA_GEOMETRY_MAGIC (0x616c4467) sits at LP_PARTITION_RESERVED_BYTES
    # (4096) and is mirrored at 8192. It is mandatory in every valid super partition,
    # unlike the group names an earlier revision grepped for - those vary per ROM
    # (main / qti_dynamic_partitions / raphael_dynamic_partitions) and an ext4 header
    # can legitimately contain no printable run at all, which misdetected Android 9
    # MIUI as dynamic. Little-endian the magic is the printable ASCII "gDla", so a
    # plain string compare needs no strings/od/hexdump in the ramdisk, and bs=1 with
    # skip= is a single lseek on a seekable device rather than 4096 reads.
    for off in 4096 8192; do
        if [ "$(dd if="$blk" bs=1 skip="$off" count=4 2>/dev/null)" = "gDla" ]; then
            echo "merge-fstab: liblp geometry magic at $off - dynamic/FBEv2" > /dev/kmsg;
            echo "1";
            return;
        fi
    done

    echo "merge-fstab: no liblp geometry at 4096/8192 - legacy/FBEv1" > /dev/kmsg;
    echo "0";
}

process_fstab_files() {
    if [ "$(rom_has_dynamic_partitions)" = "1" ]; then
        echo "merge-fstab: Loading FBEv2 fstab." > /dev/kmsg;
        echo dynamic > /tmp/.fox_fbe_gen;
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
        echo legacy > /tmp/.fox_fbe_gen;

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
