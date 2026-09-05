#!/system/bin/sh
#
# TW_FORMAT_DATA_SCRIPT (variables.h: /system/bin/formatdata.sh)
#
# Runs last in TWPartitionManager::Format_Data(), after Wipe_Encryption() and
# after the OF_WIPE_METADATA_AFTER_DATAFORMAT wipe of /metadata.
#
# Purpose:
#   1. Format /cache, which OrangeFox's Format Data never touches but
#      "fastboot -w" does (fastboot.cpp: userdata + cache + metadata).
#   2. On FBEv1 (legacy MIUI) only, leave /data raw so the ROM's own fs_mgr
#      provisions it on first boot with the ROM's mkfs parameters and the ROM's
#      SELinux labels - the same net effect as "fastboot -w" on a bootloader
#      that reports partition-type:userdata = raw. FBEv2 is left exactly as
#      OrangeFox formatted it.
#
# The FBEv1/FBEv2 decision is NOT recomputed here: merge-fstab.sh already made
# it from the liblp geometry probe at boot and recorded it in /tmp/.fox_fbe_gen.
# /tmp is a tmpfs mounted in "on init" (init.rc:47), well before the "on fs"
# trigger that execs merge-fstab.sh, so the marker is a real tmpfs file.
#
# Notes:
#   - This is toybox/mksh sh, not bash.
#   - stdout/stderr are inherited from recovery and land in /tmp/recovery.log;
#     the kmsg copy survives a hang for post-mortem via last_kmsg.
#   - check_and_run_script() discards the return value, but Exec_Cmd()'s
#     Wait_For_Child() LOGERRs a non-zero exit, so exit codes still reach the
#     log. Do not "exit 0" unconditionally.

CACHE=/dev/block/bootdevice/by-name/cache
USERDATA=/dev/block/bootdevice/by-name/userdata
MARKER=/tmp/.fox_fbe_gen
RC=0

log() {
    echo "formatdata.sh: $*"
    echo "formatdata.sh: $*" > /dev/kmsg
}

# ---------------------------------------------------------------------------
# 1. /cache parity with "fastboot -w"
#
# twrp.flags declares /cache with fs type "auto" (blkid-detected), so ext4 is
# an assumption. Verify with: blkid /dev/block/bootdevice/by-name/cache
# ---------------------------------------------------------------------------
if [ -b "$CACHE" ] && [ -x /system/bin/mke2fs ]; then
    umount -f /cache 2>/dev/null
    if mke2fs -t ext4 -b 4096 -I 512 "$CACHE"; then
        # Label the root inode the way TWRP's own Wipe_EXTFS does, otherwise
        # /cache comes back with no SELinux context.
        if [ -x /system/bin/e2fsdroid ] && [ -f /file_contexts ]; then
            e2fsdroid -e -S /file_contexts -a /cache "$CACHE" || \
                log "WARNING: e2fsdroid on cache failed"
        fi
        log "cache formatted (ext4)"
    else
        log "ERROR: mke2fs on cache failed"
        RC=1
    fi
else
    log "cache skipped ($CACHE absent or mke2fs missing)"
fi

# ---------------------------------------------------------------------------
# 2. FBEv1 only: leave /data raw
# ---------------------------------------------------------------------------
if [ ! -f "$MARKER" ]; then
    log "no $MARKER - leaving /data as OrangeFox formatted it"
    exit $RC
fi

if [ "$(cat "$MARKER")" != "legacy" ]; then
    log "FBEv2 ROM - leaving /data as OrangeFox formatted it"
    exit $RC
fi

if [ ! -b "$USERDATA" ]; then
    log "ERROR: $USERDATA is not a block device"
    exit 1
fi

# /data is MOUNTED at this point. partition.cpp:1937 ends Wipe() with
#     if (Is_Storage && Mount(false) && !Is_FBE)
# and && evaluates left to right, so Mount(false) runs even on FBE - only
# Add_MTP_Storage is skipped. Erasing the block device under a live f2fs mount
# is silently undone: the kernel still holds the superblock and checkpoint in
# the page cache and writes them back at unmount. Unmount for real, or abort -
# a partial erase that gets rewritten is worse than no erase at all.
i=0
while grep -q " /data " /proc/mounts && [ "$i" -lt 10 ]; do
    umount -f /sdcard 2>/dev/null
    umount -f /data 2>/dev/null
    i=$((i + 1))
done

if grep -q " /data " /proc/mounts; then
    log "ERROR: /data still mounted after $i attempts - ABORTING raw erase"
    exit 1
fi

# Prefer discard: it is the primitive "fastboot erase" uses, it covers the whole
# device (so neither ext4's backup superblock at 128M nor any residual file data
# survives), and it returns the blocks to the UFS pool.
if [ -x /system/bin/toybox ] && /system/bin/toybox blkdiscard "$USERDATA"; then
    log "blkdiscard OK on $USERDATA"
else
    log "blkdiscard unavailable or failed - falling back to dd"
    if ! dd if=/dev/zero of="$USERDATA" bs=1M count=32; then
        log "ERROR: dd fallback failed - /data may still hold a filesystem"
        exit 1
    fi
fi

# Discard is not required to return zeros on read, so guarantee zeros over the
# region fs_mgr probes: f2fs sb1 at 1024 and sb2 at 5120 plus the checkpoint
# area, and ext4's primary superblock at 1024.
dd if=/dev/zero of="$USERDATA" bs=1M count=10
sync
blockdev --flushbufs "$USERDATA" 2>/dev/null

log "/data left raw - the ROM's fs_mgr will provision it on first boot"
exit $RC
