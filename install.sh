##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=true

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "    Magisk Module Vold Posix   "
  ui_print "*******************************"
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want
  if [ $API != 27 ]; then
    abort "Only support Oreo 8.1"
  fi
  
  if [ -n $(getprop ro.miui.ui.version.name) ]; then
    abort "Not support platform"
  fi
  
  if [ $ARCH != "arm64" ]; then
    abort "Only support arm64 devices"
  fi
  
  MAGISKVER=`echo $MAGISK_VER_CODE|cut -c1-3`
  MAGISKINIT=magiskinit_"$MAGISKVER"
  
  if [ ! $MAGISKVER -eq 171 ] && [ ! $MAGISKVER -eq 180 ]; then
    abort "! Don't support current Magisk version. Please wait for update."
  fi

  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

  unzip -oj "$ZIPFILE" 'magiskboot' 'magiskinit_*' 'init.custom.rc' -d $TMPDIR >&2
  unzip -oj "$ZIPFILE" 'magiskboot' 'magiskinit_*' 'init.custom.rc' -d $MODPATH >&2

  patch_boot
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Here are some examples:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
  set_perm_recursive $MODPATH/system  0  0  0755  0644
  set_perm_recursive $MODPATH/system/bin  0  2000  0755  0755
  set_perm  $MODPATH/magiskboot  0  0  0755
  set_perm  $MODPATH/magiskinit_*  0  0  0755
  set_perm  $MODPATH/system/bin/vold  0  2000  0755  u:object_r:vold_exec:s0
  set_perm  $MODPATH/system/bin/fsck.exfat  0  2000  0755  u:object_r:fsck_exec:s0
  set_perm  $MODPATH/system/bin/fsck.ntfs  0  2000  0755  u:object_r:fsck_exec:s0
}

# You can add more functions to assist your custom script code
patch_boot() {
  ui_print "- Patching boot image"
  find_boot_image
  find_dtbo_image

  [ -z $BOOTIMAGE ] && abort "! Unable to detect target image"
  ui_print "- Target image: $BOOTIMAGE"
  [ -z $DTBOIMAGE ] || ui_print "- DTBO image: $DTBOIMAGE"
  [ -e "$BOOTIMAGE" ] || abort "$BOOTIMAGE does not exist!"

  ui_print "- Unpacking boot image"
  cd $TMPDIR && chmod 0755 ./magiskboot
  ./magiskboot --unpack "$BOOTIMAGE"

  case $? in
    1 )
      abort "! Unable to unpack boot image"
      ;;
    2 )
      ui_print "- ChromeOS boot image detected"
      abort "! Unsupport type"
      ;;
    3 )
      ui_print "! Sony ELF32 format detected"
      abort "! Please use BootBridge from @AdrianDC to flash Magisk"
      ;;
    4 )
      ui_print "! Sony ELF64 format detected"
      abort "! Stock kernel cannot be patched, please use a custom kernel"
  esac

  ui_print "- Checking ramdisk status"
  ./magiskboot --cpio ramdisk.cpio test
  case $? in
    0 )  # Stock boot
      ui_print "- Stock boot image detected"
      abort "! Please install Magisk first"
      ;;
    1 )  # Magisk patched
      ui_print "- Magisk patched boot image detected"
      ;;
    2 ) # Other patched
      ui_print "! Boot image patched by unsupported programs"
      abort "! Please restore stock boot image"
      ;;
  esac

  ui_print "- Patching ramdisk"

  if [ ! -f $MAGISKINIT ]; then
    abort "! Can't find $MAGISKINIT, please check again."
  fi

  ./magiskboot --cpio ramdisk.cpio \
  "add 750 init $MAGISKINIT" \
  "add 755 vold $MODPATH/system/bin/vold" \
  "add 750 init.custom.rc init.custom.rc"

  ui_print "- Repacking boot image"
  ./magiskboot --repack "$BOOTIMAGE" || abort "! Unable to repack boot image!"

  ./magiskboot --cleanup

  ui_print "- Flashing new boot image"
  flash_image new-boot.img "$BOOTIMAGE" || abort "! Insufficient partition size"
  rm -f new-boot.img
}
