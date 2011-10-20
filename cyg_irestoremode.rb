#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ipsw_ext'
require 'win32device'

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
  return unless IPSW_VERSION == "ios5_0"
  p "sending root ticket" #in iOS5
  puts filename
  dev.send_file(filename)
  # 21.0  CTL    40 00 00 00  00 00 07 00                            VENDOR            196us        43.1.0
  # 21.0  USTS   c0000004                                            stall pid         4.7ms        43.2.0
  dev.close
  dev.open
  dev.send_command("ticket")
end

def send_ibec(dev, filename)
  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  puts "sending iBEC"
  puts filename
  dev.send_file(filename)
end

def send_ticket_and_ibec(ipsw_info)
  dev = Win32Device.new
  ret = dev.open
  return if ret < 0

  send_ticket(dev, FILE_AP_TICKET)
  send_ibec(dev, ipsw_info[:file_ibec])
  dev.send_command("go", 0x1)

  dev.close
end

def send_ramdisk_and_kernel(ipsw_info)
  dev = Win32Device.new
  ret = dev.open
  return if ret < 0

  send_ticket(dev, FILE_AP_TICKET)
  send_apple_logo(dev, ipsw_info[:file_applelog])
  send_ramdisk(dev, ipsw_info[:file_ramdisk])
  send_device_tree(dev, ipsw_info[:file_devicetree])
  send_kernel_cache(dev, ipsw_info[:file_kernelcache])

  dev.send_command("bootx", 0x1)

  #dev.reset
  dev.close
end

def wait_for_reboot
  p "sleeping, press enter key to continue"
  gets
end

def enter_restore(ipsw_info)
  send_ticket_and_ibec(ipsw_info)
  wait_for_reboot()
  send_ramdisk_and_kernel(ipsw_info)
end

if __FILE__ == $0
  #ipsw_info = get_ipsw_info("m68ap", "ios3_1_3")
  ipsw_info = get_ipsw_info("n88ap", IPSW_VERSION)
  unzip_ipsw ipsw_info
  enter_restore(ipsw_info)
end