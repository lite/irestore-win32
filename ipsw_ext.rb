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
FILE_MANIFEST_PLIST = File.join(PATH_DMG, "BuildManifest.plist")
FILE_MANIFEST       = File.join(PATH_DMG, "Firmware/all_flash/all_flash.n88ap.production/manifest")
# 
PATH_DMG_NEW        = File.join(PATH_BASE, "ipsw/dmg_new")
# 
FILE_IBEC           = File.join(PATH_DMG_NEW, "Firmware/dfu/iBEC.n88ap.RELEASE.dfu")
FILE_APPLELOG       = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.n88ap.production/applelogo.s5l8920x.img3")
FILE_DEVICETREE     = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.n88ap.production/DeviceTree.n88ap.img3")
FILE_KERNELCACHE    = File.join(PATH_DMG_NEW, "kernelcache.release.n88")
FILE_LLB            = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.n88ap.production/LLB.n88ap.RELEASE.img3")
FILE_IMGDIR         = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.n88ap.production")

### 4.3.3
# FILE_IPSW           = File.join(PATH_BASE, "iPhone2,1_4.3.3_8J2_Restore.ipsw")
# FILE_RESTOREDMG     = File.join(PATH_DMG, "038-1417-003.dmg")
# FILE_RAMDISK        = File.join(PATH_DMG_NEW, "038-1447-003.dmg")

### 4.3.4
# FILE_IPSW           = File.join(PATH_BASE, "iPhone2,1_4.3.4_8K2_Restore.ipsw")
# FILE_RESTOREDMG     = File.join(PATH_DMG, "038-2191-001.dmg")
# FILE_RAMDISK        = File.join(PATH_DMG_NEW, "038-2169-001.dmg")

### 4.3.5
FILE_IPSW           = File.join(PATH_BASE, "iPhone2,1_4.3.5_8L1_Restore.ipsw")
FILE_RESTOREDMG     = File.join(PATH_DMG, "038-2287-002.dmg")
FILE_RAMDISK        = File.join(PATH_DMG_NEW, "038-2257-002.dmg")
