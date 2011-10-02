s-irecovery.exe -c "getenv build-version"
s-irecovery.exe -c "getenv build-style"
s-irecovery.exe -c "setenv auto-boot false"
s-irecovery.exe -c "saveenv"

s-irecovery.exe -r
echo "send IBEC"
#s-irecovery.exe -f "C:\cygwin\home\dli\tools\iOS\ipsw\dmg_new\Firmware\dfu\iBEC.n88ap.RELEASE.dfu"
s-irecovery.exe -f "`cygpath -w ~/tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu`" # s-irecovery.exe not works on unix path
#s-irecovery.exe -f "../tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu" # s-irecovery.exe not works 
s-irecovery.exe -c "setenv auto-boot false"

s-irecovery.exe -c "saveenv"
s-irecovery.exe -c "go"

echo "sleep..."
sleep 5

s-irecovery.exe -r
echo "send applelogo"
s-irecovery.exe -f "C:\cygwin\home\dli\tools\iOS\ipsw\dmg_new\Firmware\all_flash\all_flash.n88ap.production\applelogo.s5l8920x.img3"
s-irecovery.exe -c "setpicture 0"
s-irecovery.exe -c "bgcolor 0 0 255"

echo "send ramdisk"
s-irecovery.exe -r
s-irecovery.exe -f "C:\cygwin\home\dli\tools\iOS\ipsw\dmg_new\Firmware\038-1447-003.dmg"
s-irecovery.exe -c "ramdisk"

echo "send devicetree"
s-irecovery.exe -r
s-irecovery.exe -f "C:\cygwin\home\dli\tools\iOS\ipsw\dmg_new\Firmware\all_flash\all_flash.n88ap.production\DeviceTree.n88ap.img3"
s-irecovery.exe -c "devicetree"

echo "send kernelcache"
s-irecovery.exe -r
s-irecovery.exe -f "C:\cygwin\home\dli\tools\iOS\ipsw\dmg_new\kernelcache.release.n88"
s-irecovery.exe -c "setenv boot-args rd=md0 nand-enable-reformat=1 -progress"

echo "booting..."
s-irecovery.exe -c "bootx"
