#!/usr/bin/env bash

irecovery -c "getenv build-version"
irecovery -c "getenv build-style"
irecovery -c "setenv auto-boot false"
irecovery -c "saveenv"

irecovery -r
echo "send IBEC"
irecovery -f "~/tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu"
irecovery -c "setenv auto-boot false"

irecovery -c "saveenv"
irecovery -c "go"

echo "sleep..."
sleep 5

irecovery -r
echo "send applelogo"
irecovery -f "~/tools/iOS/ipsw/dmg_new/Firmware/all_flash/all_flash.n88ap.production/applelogo.s5l8920x.img3"
irecovery -c "setpicture 0"
irecovery -c "bgcolor 0 0 255"

echo "send ramdisk"
irecovery -r
irecovery -f "~/tools/iOS/ipsw/dmg_new/038-1447-003.dmg"
irecovery -c "ramdisk"

echo "send devicetree"
irecovery -r
irecovery -f "~/tools/iOS/ipsw/dmg_new/Firmware/all_flash/all_flash.n88ap.production/DeviceTree.n88ap.img3"
irecovery -c "devicetree"

echo "send kernelcache"
irecovery -r
irecovery -f "~/tools/iOS/ipsw/dmg_new/kernelcache.release.n88"
irecovery -c "setenv boot-args rd=md0 nand-enable-reformat=1 -progress"

echo "booting..."
irecovery -c "bootx"
