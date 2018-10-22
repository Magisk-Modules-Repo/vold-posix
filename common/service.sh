#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode
# More info in the main Magisk thread

magiskpolicy --live "permissive priv_app"
magiskpolicy --live "permissive platform_app"
magiskpolicy --live "allow vfat vfat filesystem associate"
magiskpolicy --live "allow vold labeledfs filesystem relabelfrom"
magiskpolicy --live "allow vold unlabeled filesystem relabelfrom"
magiskpolicy --live "allow vold vfat filesystem { mount unmount relabelto relabelfrom }"
magiskpolicy --live "allow vold vfat dir { getattr setattr }"
magiskpolicy --live "allow vold mnt_media_rw_stub_file dir { open read }"
magiskpolicy --live "allow fsck_untrusted vfat dir getattr"
magiskpolicy --live "allow fsck_untrusted vfat file getattr"
magiskpolicy --live "allow fsck_untrusted rootfs blk_file getattr"
magiskpolicy --live "allow fsck_untrusted block_device dir getattr"
magiskpolicy --live "allow fsck_untrusted system_file file entrypoint"
magiskpolicy --live "allow fsck_untrusted fsck_untrusted capability sys_admin"
magiskpolicy --live "allow system_server vfat dir { read open getattr }"
magiskpolicy --live "allow system_server vfat file { read open getattr }"
magiskpolicy --live "allow mediaprovider vfat dir { open read search getattr }"
magiskpolicy --live "allow mediaprovider vfat file { open read getattr }"
magiskpolicy --live "allow { vold system_app untrusted_app_all } vfat filesystem getattr"
magiskpolicy --live "allow { vold system_app untrusted_app_all } vfat dir { open getattr setattr read write search ioctl add_name remove_name create reparent rename rmdir }"
magiskpolicy --live "allow { vold system_app untrusted_app_all } vfat file { open read write append ioctl lock create rename getattr setattr unlink }"

stop vold && start vold
