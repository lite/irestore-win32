#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'win32device'

def test_getdevpath dev
  dev.get_iboot
end

def test_reboot dev
  dev.open
  dev.send_command "reboot"
  dev.close
end

def test_getenv dev
  dev.open
  cmd = "getenv build-version"
  dev.send_command(cmd)
  puts dev.recv_command
  dev.close
end

def test_set_interface dev
  dev.open
  dev.set_interface(1, 0)
  dev.close
end

def test_ibec dev
  dev.open
  #dev.reset
  #dev.init
  #dev.set_config(1)
  #dev.set_interface(1, 0)

  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  p "sending iBEC"
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu'
  dev.send_file(filename)

  dev.send_command("go", 0x1)

  dev.close
end

def test_enter_mode  dev
  dev.open
  dev.init
  dev.set_interface(1, 0)

  test_applogo dev
  test_ramdisk dev
  test_devicetree dev
  test_kernel dev

  dev.reset
  dev.close
end

def test_applogo dev
  p "sending apple logo"
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/Firmware/all_flash/all_flash.n88ap.production/applelogo.s5l8920x.img3'
  dev.send_file(filename)

  dev.send_command("setpicture 0")
  dev.send_command("bgcolor 0 0 0")
end

def test_ramdisk dev
  p "sending ramdisk"
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/038-2257-002.dmg'
  dev.send_file(filename)

  dev.send_command("ramdisk")
end

def test_devicetree dev
  p "sending device tree"
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/Firmware/all_flash/all_flash.n88ap.production/DeviceTree.n88ap.img3'
  dev.send_file(filename)

  dev.send_command("devicetree")
end

def test_kernel dev
  p "sending kernel"
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/kernelcache.release.n88'
  dev.send_file(filename)

  p "booting"
  dev.send_command("setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
  dev.send_command("bootx", 0x1)
end

if __FILE__ == $0
  dev = Win32Device.new
  #test_reboot dev
  #test_getdevpath dev
  #test_set_interface dev
  #test_getenv dev
  test_ibec dev
  #test_enter_mode dev
end
