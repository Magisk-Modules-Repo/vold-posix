# Vold - exFAT/NTFS/EXT4/F2FS Support

Since AOSP only support vfat for external sdcard. Add exfat/ntfs/ext4/f2fs support for vold.

## Requirements
- Android 8.1 AOSP-like system.
- arm64 system. 
  (Compile ``vold/fuse/fsck`` yourself if you have other arch devices)

*__Note:__ Don't use this module if you still want to use the built-in exfat driver from your rom!

## Instructions
- Don't format sdcard on the phone, or otherwise it will format to FAT32.
- OTG tested on my phone, works as well as external sdcard.
- Since v2.0 will patch the boot image. After you flash your boot image or upgrade the magisk, module will auto patch it again while booting. After that you need reboot to apply the patch.
- Only support Magisk v17.1 & v18.0 at the time. 

*I will only support from current stable version(ensure) to current beta version(maybe). Or you can compile magiskinit by yourself and put it in the module folder as magiskinit_$version, it will auto patch the valid version.*

## Supported Magisk
- Magisk 17.1 
- Magisk 18.0

## Changelog
- v1.0 inital release
- v2.0 fixes issue with "Android for Work" feature(island/etc).
- v2.0.1 merge magisk 18.0

## Known issue
- Can't use sdcard in work space, this's Google's limitation after Oreo :(

You can report bug [here](https://github.com/null4n/vold-posix/issues) if occurs issue.

vold source code can found [here](https://github.com/null4n/system_vold).

magiskinit soucre code can found [here](https://github.com/null4n/Magisk/blob/vold-posix/native/jni/init.c).

exfat/ntfs use fuse driver. soucre code is from [LineageOS](https://github.com/LineageOS).

- [fuse](https://github.com/LineageOS/android_external_fuse)
- [exfat](https://github.com/LineageOS/android_external_exfat)
- [ntfs](https://github.com/LineageOS/android_external_ntfs-3g)
