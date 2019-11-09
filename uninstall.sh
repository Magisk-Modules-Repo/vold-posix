#!/system/bin/sh
##########################################################################################
# Preparation
##########################################################################################
MODDIR=${0%/*}

log_print() {
  echo "Vold-posix: $1" >> /cache/magisk.log
}

error() {
  echo "Vold-posix: error: $1" >> /cache/magisk.log
  exit 1
}

require_new_magisk() {
  log_print "***********************************"
  log_print " Please install the latest Magisk! "
  log_print "***********************************"
  exit 1

# Default permissions
umask 022

# Load utility functions
if [ -f /data/adb/magisk/util_functions.sh ]; then
  . /data/adb/magisk/util_functions.sh
  NVBASE=/data/adb
else
  require_new_magisk
fi

restore_boot() {
  TMPDIR=/dev/tmp
  INSTALLER=$TMPDIR/install

  if [ ! $MAGISKVER -eq 171 ] && [ $MAGISKVER -lt 200 ]; then
    error "! Only support Magisk 17.1 or 20+."
  fi

  # Initial cleanup
  rm -rf $TMPDIR 2>/dev/null
  mkdir -p $INSTALLER

  # Preperation for flashable zips
  setup_flashable

  # Mount partitions
  mount_partitions

  # Setup busybox and binaries
  $BOOTMODE && boot_actions

  get_flags
  find_boot_image
  find_manager_apk

  eval $BOOTSIGNER -verify < $BOOTIMAGE && BOOTSIGNED=true
  $BOOTSIGNED && log_print "- Boot image is signed with AVB 1.0"

  [ -z $BOOTIMAGE ] && error "! Unable to detect target image"
  log_print "- Target image: $BOOTIMAGE"
  [ -e "$BOOTIMAGE" ] || error "$BOOTIMAGE does not exist!"

  log_print "- Unpacking boot image"
  /data/adb/magisk/magiskboot --unpack "$BOOTIMAGE"

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
      error "! Unsupport type"
      ;;
    4 )
      log_print "! Sony ELF64 format detected"
      error "! Unsupport type"
  esac

  log_print "- Checking ramdisk status"
  if [ -e ramdisk.cpio ]; then
    /data/adb/magisk/magiskboot --cpio ramdisk.cpio test
    STATUS=$?
  else
    # Stock A only system-as-root
    STATUS=0
  fi
  case $((STATUS & 3)) in
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

  if [ $((STATUS & 8)) -ne 0 ]; then
    # Possibly using 2SI, export env var
    export TWOSTAGEINIT=true
  fi

  log_print "- Patching ramdisk"

  /data/adb/magisk/magiskboot cpio ramdisk.cpio \
  "rm -r overlay.d/sbin"

  if [ $((STATUS & 4)) -ne 0 ]; then
    log_print "- Compressing ramdisk"
    /data/adb/magisk/magiskboot --cpio ramdisk.cpio compress
  fi

  log_print "- Repacking boot image"
  $MODDIR/magiskboot --repack "$BOOTIMAGE" || error "! Unable to repack boot image!"

  log_print "- Flashing new boot image"
  if ! flash_image new-boot.img "$BOOTIMAGE"; then
    log_print "- Compressing ramdisk to fit in partition"
    /data/adb/magisk/magiskboot --cpio ramdisk.cpio compress
    /data/adb/magisk/magiskboot --repack "$BOOTIMAGE"
  flash_image new-boot.img "$BOOTIMAGE" || error "! Insufficient partition size"
  log_print "- Done, reboot to apply."
  rm -rf $TMPDIR
}

restore_boot
