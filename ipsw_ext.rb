#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'

#if /darwin/ =~ RUBY_PLATFORM
#  PATH_IRECOVERY = File.join(File.dirname(__FILE__), "irecovery");
#else
#  PATH_IRECOVERY = File.join(File.dirname(__FILE__), "s-irecovery.exe");
#end
#
#PATH_BASE = File.expand_path("~/tools/iOS")
#p PATH_BASE
#
#PATH_DMG = File.join(PATH_BASE, "ipsw/dmg")
#
##
##### iphone 3gs
#DEVICE_BOARDCONFIG = "n88ap"
#PATH_DMG_NEW = File.join(PATH_BASE, "ipsw/dmg_new")
#FILE_KERNELCACHE = File.join(PATH_DMG_NEW, "kernelcache.release.n88")
#FILE_APPLELOG = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/applelogo.s5l8920x.img3")
#
#### 4.3.5
#FILE_IPSW = File.join(PATH_BASE, "iPhone2,1_4.3.5_8L1_Restore.ipsw")
#FILE_RESTOREDMG = File.join(PATH_DMG, "038-2287-002.dmg")
#FILE_RAMDISK = File.join(PATH_DMG_NEW, "038-2257-002.dmg")
#FILE_MANIFEST_PLIST = File.join(PATH_DMG, "BuildManifest.plist")
#
## img3 files
#FILE_MANIFEST = File.join(PATH_DMG, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/manifest")
#FILE_IBEC = File.join(PATH_DMG_NEW, "Firmware/dfu/iBEC.#{DEVICE_BOARDCONFIG}.RELEASE.dfu")
#FILE_DEVICETREE = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/DeviceTree.#{DEVICE_BOARDCONFIG}.img3")
#FILE_LLB = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production/LLB.#{DEVICE_BOARDCONFIG}.RELEASE.img3")
#FILE_IMGDIR = File.join(PATH_DMG_NEW, "Firmware/all_flash/all_flash.#{DEVICE_BOARDCONFIG}.production")

PATH_BASE = File.expand_path("~/tools/iOS")
PATH_DMG = File.join(PATH_BASE, "ipsw/dmg")
#PATH_DMG_NEW = File.join(PATH_BASE, "ipsw/dmg_new")
PATH_DMG_NEW = PATH_DMG

def unzip_ipsw(ipsw_info)
  system("mkdir -p #{PATH_DMG}")
  system("unzip -n -d #{PATH_DMG} #{ipsw_info[:file_ipsw]}")
end

def firmware_info(model, ipsw)
  get_firmware_files(model, ipsw)
end

def get_firmware_info_table
  {
      # iphone 2g
      "m68ap"=> {
          :file_manifest_plist => "BuildManifest.plist",
          :file_manifest => "Firmware/all_flash/all_flash.m68ap.production/manifest",

          :file_imgdir => "Firmware/all_flash/all_flash.m68ap.production",
          :file_kernelcache => "kernelcache.release.s5l8900x",
          :file_applelog => "Firmware/all_flash/all_flash.m68ap.production/applelogo.s5l8900x.img3",
          :file_ibec => "Firmware/dfu/iBEC.m68ap.RELEASE.dfu",
          :file_devicetree => "Firmware/all_flash/all_flash.m68ap.production/DeviceTree.m68ap.img3",
          :file_llb => "Firmware/all_flash/all_flash.m68ap.production/LLB.m68ap.RELEASE.img3",

          "ios3_1_3" => {
              :file_ipsw => "iPhone1,1_3.1.3_7E18_Restore.ipsw",
              :file_restoredmg => "018-6482-014.dmg",
              :file_ramdisk => "018-6494-014.dmg",
          },
      },
      # iphone 3gs
      "n88ap"=> {
          :file_manifest_plist => "BuildManifest.plist",
          :file_manifest => "Firmware/all_flash/all_flash.n88ap.production/manifest",

          :file_imgdir => "Firmware/all_flash/all_flash.n88ap.production",
          :file_kernelcache => "kernelcache.release.n88",
          :file_applelog => "Firmware/all_flash/all_flash.n88ap.production/applelogo.s5l8920x.img3",
          :file_ibec => "Firmware/dfu/iBEC.n88ap.RELEASE.dfu",
          :file_devicetree => "Firmware/all_flash/all_flash.n88ap.production/DeviceTree.n88ap.img3",
          :file_llb => "Firmware/all_flash/all_flash.n88ap.production/LLB.n88ap.RELEASE.img3",

          "ios4_3_5" => {
              :file_ipsw => "iPhone2,1_4.3.5_8L1_Restore.ipsw",
              :file_restoredmg => "038-2287-002.dmg",
              :file_ramdisk => "038-2257-002.dmg",
          },

          "ios5_0" => {
              :file_ipsw => "iPhone2,1_5.0_9A334_Restore.ipsw",
              :file_restoredmg => "dmg/018-7873-736.dmg",
              :file_ramdisk => "018-7919-343.dmg",
          },
      }
  }
end

def get_ipsw_info(model, ipsw_ver)
  info = get_firmware_info_table

  {
      :file_manifest_plist => File.join(PATH_DMG, info[model][:file_manifest_plist]),
      :file_manifest => File.join(PATH_DMG, info[model][:file_manifest]),

      :file_imgdir => File.join(PATH_DMG_NEW, info[model][:file_imgdir]),
      :file_kernelcache =>File.join(PATH_DMG_NEW, info[model][:file_kernelcache]),
      :file_applelog =>File.join(PATH_DMG_NEW, info[model][:file_applelog]),
      :file_ibec => File.join(PATH_DMG_NEW, info[model][:file_ibec]),
      :file_devicetree => File.join(PATH_DMG_NEW, info[model][:file_devicetree]),
      :file_llb => File.join(PATH_DMG_NEW, info[model][:file_llb]),

      :file_ipsw => File.join(PATH_BASE, info[model][ipsw_ver][:file_ipsw]),
      :file_restoredmg => File.join(PATH_DMG, info[model][ipsw_ver][:file_restoredmg]),
      :file_ramdisk => File.join(PATH_DMG_NEW, info[model][ipsw_ver][:file_ramdisk]),
  }
end

