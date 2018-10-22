# Vold - exFAT/NTFS/EXT4/F2FS Support

Since AOSP only support vfat for external sdcard. Add exfat/ntfs/ext4/f2fs support for vold.

## Requirements
- Android 8.1 AOSP-like system.
- arm64 system. (Compile yourself if you have other arch devices)

*__Note:__ If your ROM has supported exfat and you still want to use the built-in driver, don't use this module!

You can report bug [here](https://github.com/noname8964/vold-posix/issues) if occurs issue.

vold source code can found [here](https://github.com/noname8964/system_vold).

exfat/ntfs use fuse driver. soucre code is from [LineageOS](https://github.com/LineageOS).

- [fuse](https://github.com/LineageOS/android_external_fuse)
- [exfat](https://github.com/LineageOS/android_external_exfat)
- [ntfs](https://github.com/LineageOS/android_external_ntfs-3g)
