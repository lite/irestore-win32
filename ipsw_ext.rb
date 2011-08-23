#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'

if /darwin/ =~ RUBY_PLATFORM
  PATH_IRECOVERY = File.join(File.dirname(__FILE__), "irecovery");
else
  PATH_IRECOVERY = File.join(File.dirname(__FILE__), "s-irecovery.exe");
end

PATH_BASE           = File.expand_path("~/tools/iOS")
p PATH_BASE

PATH_DMG            = File.join(PATH_BASE, "ipsw/dmg")

# 
#### iphone 3gs
# DEVICE_BOARDCONFIG  = "m68ap"
# PATH_DMG_NEW        = File.join(PATH_BASE, "ipsw/dmg_new")
# FILE_KERNELCACHE    = File.join(PATH_DMG_NEW, "kernelcache.release.n88")
# FILE_APPLELOG       = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/applelogo.s5l8920x.img3")

### 4.3.3
# FILE_IPSW           = File.join(PATH_BASE, "iPhone2,1_4.3.3_8J2_Restore.ipsw")
# FILE_RESTOREDMG     = File.join(PATH_DMG, "038-1417-003.dmg")
# FILE_RAMDISK        = File.join(PATH_DMG_NEW, "038-1447-003.dmg")
# FILE_MANIFEST_PLIST = File.join(PATH_DMG, "BuildManifest.plist")

### 4.3.4
# FILE_IPSW           = File.join(PATH_BASE, "iPhone2,1_4.3.4_8K2_Restore.ipsw")
# FILE_RESTOREDMG     = File.join(PATH_DMG, "038-2191-001.dmg")
# FILE_RAMDISK        = File.join(PATH_DMG_NEW, "038-2169-001.dmg")
# FILE_MANIFEST_PLIST = File.join(PATH_DMG, "BuildManifest.plist")

### 4.3.5
# FILE_IPSW           = File.join(PATH_BASE, "iPhone2,1_4.3.5_8L1_Restore.ipsw")
# FILE_RESTOREDMG     = File.join(PATH_DMG, "038-2287-002.dmg")
# FILE_RAMDISK        = File.join(PATH_DMG_NEW, "038-2257-002.dmg")
# FILE_MANIFEST_PLIST = File.join(PATH_DMG, "BuildManifest.plist")

#### iphone
DEVICE_BOARDCONFIG  = "m68ap"
PATH_DMG_NEW        = PATH_DMG
FILE_KERNELCACHE    = File.join(PATH_DMG_NEW, "kernelcache.release.s5l8900x")
FILE_APPLELOG       = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/applelogo.s5l8900x.img3")

### 3.1.3
FILE_IPSW           = File.join(PATH_BASE, "iPhone1,1_3.1.3_7E18_Restore.ipsw")
FILE_RESTOREDMG     = File.join(PATH_DMG, "018-6482-014.dmg")
FILE_RAMDISK        = File.join(PATH_DMG_NEW, "018-6494-014.dmg")
FILE_MANIFEST_PLIST = File.join(PATH_DMG, "BuildManifesto.plist")

# img3 files
FILE_MANIFEST       = File.join(PATH_DMG, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/manifest")
FILE_IBEC           = File.join(PATH_DMG_NEW, "Firmware/dfu/iBEC.#{DEVICE_BOARDCONFIG}.RELEASE.dfu")
FILE_DEVICETREE     = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/DeviceTree.#{DEVICE_BOARDCONFIG}.img3")
FILE_LLB            = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/LLB.#{DEVICE_BOARDCONFIG}.RELEASE.img3")
FILE_IMGDIR         = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production")

### unzip
system("mkdir -p #{PATH_DMG}")
system("unzip -d #{PATH_DMG} #{FILE_IPSW}")
