#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ipsw_ext'
require 'win32device'

def send_ibec(filename)
  dev = Win32Device.new
  dev.open

  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  puts "sending iBEC"
  puts filename
  dev.send_file(filename)

  dev.send_command("go", 0x1)

  dev.reset
  dev.close

  #dev.sleep(5)
  sleep(5)
end

def send_apple_logo(dev, filename)
  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  p "sending apple logo"
  puts filename
  dev.send_file(filename)

  dev.send_command("setpicture 0")
  dev.send_command("bgcolor 0 0 0")
end

def send_ramdisk(dev, filename)
  p "sending ramdisk"
  puts filename
  dev.send_file(filename)

  dev.send_command("ramdisk")
end

def send_device_tree(dev, filename)
  p "sending device tree"
  puts filename
  dev.send_file(filename)

  dev.send_command("devicetree")
end

def send_kernel_cache(dev, filename)
  p "sending kernel"
  puts filename
  dev.send_file(filename)

  p "booting"
  dev.send_command("setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
end

def send_ticket(dev, filename)
  p "sending root ticket" #in iOS5
  puts filename
  dev.send_file(filename)

  dev.send_command("ticket")
end

def send_ramdisk_and_kernel(ipsw_info)
  dev = Win32Device.new
  dev.open

  send_ticket(dev, ipsw_info[:file_ap_ticket])
  send_apple_logo(dev, ipsw_info[:file_applelog])
  send_ramdisk(dev, ipsw_info[:file_ramdisk])
  send_device_tree(dev, ipsw_info[:file_devicetree])
  send_kernel_cache(dev, ipsw_info[:file_kernelcache])

  dev.send_command("bootx", 0x1)

  dev.reset
  dev.close
end

def enter_restore(ipsw_info)
  send_ibec(ipsw_info[:file_ibec])
  send_ramdisk_and_kernel(ipsw_info)
end

if __FILE__ == $0
  #ipsw_info = get_ipsw_info("m68ap", "ios3_1_3")
  ipsw_info = get_ipsw_info("n88ap", "ios5_0")
  unzip_ipsw ipsw_info
  enter_restore ipsw_info
end