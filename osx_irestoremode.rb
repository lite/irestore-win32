#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'ipsw_ext'
require 'idevice'

def enter_restore
  devs = AppleDevice.available_devices

  if devs[0].kind_of?(RecoveryV2Mode)
    x = devs[0].open

    x.send_command("getenv build-version")
    p x.recv_command.split("\x00")
   
    res = x.send_command("getenv build-style")
    p x.recv_command.split("\x00")
  
    x.send_command("setenv auto-boot false")
    x.send_command("saveenv")
    # x.send_command("reboot")
  
    p "sending iBEC"
    File.open(FILE_IBEC) do |f|
      x.send_file(f)
    end

    x.send_command("setenv auto-boot false")
    x.send_command("saveenv")
    x.send_command("go")
  
    x.close
  
    sleep(5)
  
    x = devs[0].open
  
    p "sending apple logo"
  
    File.open(FILE_APPLELOG) do |f|
      x.send_file(f)
    end
  
    x.send_command("setpicture 0")
    x.send_command("bgcolor 0 0 0")

    p "sending ramdisk"
    File.open(FILE_RAMDISK) do |f|
      x.send_file(f)
    end
  
    x.send_command("ramdisk")

    p "sending device tree"
    File.open(FILE_DEVICETREE) do |f|
      x.send_file(f)
    end

    x.send_command("devicetree")

    p "sending kernel"
    File.open(FILE_KERNELCACHE) do |f|
      x.send_file(f)
    end

    p "booting"
    x.send_command("setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
    x.send_command("bootx")

    # pp x.recv_buffer.split("\x00")

    x.close()
    p "sleeping"
    sleep(10)
  
  end
end

if __FILE__ == $0
  enter_restore
end