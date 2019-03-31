#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode

log_print() {
  echo "Vold-posix: $1" >> /cache/magisk.log
}

error() {
  echo "Vold-posix: error: $1" >> /cache/magisk.log
  exit 1
}

# Load utility functions
# Load utility functions
if [ -f /data/adb/magisk/util_functions.sh ]; then
  . /data/adb/magisk/util_functions.sh
  NVBASE=/data/adb
else
  error "Can't load magisk environment!"
fi

MAGISKVER=`echo $MAGISK_VER_CODE|cut -c1-3`
MAGISKINIT=magiskinit_"$MAGISKVER"

patch_boot() {
  TMPDIR=/dev/tmp
  INSTALLER=$TMPDIR/install

  # Initial cleanup
  rm -rf $TMPDIR 2>/dev/null
  mkdir -p $INSTALLER

  # Mount partitions
  mount_partitions

  log_print "- Patching boot image"
  find_boot_image
  find_dtbo_image

  log_print "- Patching ramdisk"
  if [ ! -f $MODDIR/$MAGISKINIT ]; then
    error "! Don't support current Magisk version. Please wait for update."
  fi

  [ -z $BOOTIMAGE ] && error "! Unable to detect target image"
  log_print "- Target image: $BOOTIMAGE"
  [ -z $DTBOIMAGE ] || log_print "- DTBO image: $DTBOIMAGE"
  [ -e "$BOOTIMAGE" ] || error "$BOOTIMAGE does not exist!"

  log_print "- Unpacking boot image"
  cd $INSTALLER
  $MODDIR/magiskboot --unpack "$BOOTIMAGE"

  case $? in
    1 )
      error "! Unable to unpack boot image"
      ;;
    2 )
      log_print "- ChromeOS boot image detected"
      error "! Unsupport type"
      ;;
    3 )
      log_print "! Sony ELF32 format detected"
      error "! Please use BootBridge from @AdrianDC to flash Magisk"
      ;;
    4 )
      log_print "! Sony ELF64 format detected"
      error "! Stock kernel cannot be patched, please use a custom kernel"
  esac

  log_print "- Checking ramdisk status"
  $MODDIR/magiskboot --cpio ramdisk.cpio test
  case $? in
    0 )  # Stock boot
      log_print "- Stock boot image detected"
      error "! Please install Magisk first"
      ;;
    1 )  # Magisk patched
      log_print "- Magisk patched boot image detected"
      ;;
    2 ) # Other patched
      log_print "! Boot image patched by unsupported programs"
      error "! Please restore stock boot image"
      ;;
  esac

  $MODDIR/magiskboot --cpio ramdisk.cpio \
  "add 750 init $MODDIR/$MAGISKINIT" \
  "add 755 vold $MODDIR/system/bin/vold" \
  "add 750 init.custom.rc $MODDIR/init.custom.rc"

  log_print "- Repacking boot image"
  $MODDIR/magiskboot --repack "$BOOTIMAGE" || error "! Unable to repack boot image!"

  #$MODDIR/magiskboot --cleanup

  log_print "- Flashing new boot image"
  flash_image new-boot.img "$BOOTIMAGE" || error "! Insufficient partition size"
  log_print "- Done, reboot to apply."
  rm -rf $TMPDIR
}

diff "$MODDIR/$MAGISKINIT" /sbin/magiskinit || patch_boot
