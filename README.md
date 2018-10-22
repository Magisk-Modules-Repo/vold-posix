# Vold - exFAT/NTFS/EXT4/F2FS Support

Since AOSP only support vfat for external sdcard. Add exfat/ntfs/ext4/f2fs support for vold.
vold source code can found [here](https://github.com/noname8964/system_vold).
exfat/ntfs use fuse driver.
soucre code is from [LineageOS](https://github.com/LineageOS).
[fuse](https://github.com/LineageOS/android_external_fuse)
[exfat](https://github.com/LineageOS/android_external_exfat)
[ntfs](https://github.com/LineageOS/android_external_ntfs-3g)

If your ROM has supported exfat and you still want to use the built-in driver, don't use this module!

Please note, this only support Oreo 8.1 and arm64-v8a. Other arch can compile yourself.
