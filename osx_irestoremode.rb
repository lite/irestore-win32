#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'ipsw_ext'
require 'idevice'

def send_ibec(filename)
  dev = AppleDevice.new
  dev.open

  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  p "sending iBEC"
  dev.send_file(filename)

  dev.send_command("go")

  dev.close
end

def send_kernel_cache(dev, filename)
  p "sending kernel"
  dev.send_file(filename)

  dev.send_command("setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
end

def send_device_tree(dev, filename)
  p "sending device tree"
  dev.send_file(filename)

  dev.send_command("devicetree")
end

def send_ramdisk(dev, filename)
  p "sending ramdisk"
  dev.send_file(filename)

  dev.send_command("ramdisk")
end

def send_apple_logo(dev, filename)
  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  p "sending apple logo"
  dev.send_file(filename)

  dev.send_command("setpicture 0")
  dev.send_command("bgcolor 0 0 0")
end

def send_ticket
  p "sending root ticket" #in iOS5
                          #dev.send_command("ticket")

                          #30 82 0a cb  30 0b 06 09  2a 86 48 86  f7 0d 01 01  0...0...*.H.....  3.6ms       218.1.0
                          #05 31 82 02  d7 81 08 0c  5d 04 3a 14  00 00 00 82  .1......].:.....              218.1.16
                          #04 20 89 00  00 83 04 00  00 00 00 84  04 01 00 00  . ..............              218.1.32
                          #00 85 04 01  00 00 00 86  13 69 42 6f  6f 74 2d 31  .........iBoot-1              218.1.48
                          #32 31 39 2e  34 33 2e 33  32 7e 31 35  87 14 2f a7  219.43.32.15../.              218.1.64

                          #4d 8a ce cc  dd f2 1a 08  c7 b6 fa 3f  80 14 13 9f  M..........?....              218.1.2688
                          #f7 1b c2 5e  94 d2 b3 ba  97 db bc f2  00 e3 9e 01  ...^............              218.1.2704
                          #d3 81 c6 f7  26 cb 00 7a  b6 59 7c 9f  93 93 26 1c  ....&..z.Y....&.              218.1.2720
                          #83 ac b9 8d  8a 27 d8 75  a9 26 c9 d9  4c 2a 78 d2  .....'.u.&..L*x.          218.1.2736
                          #59 aa 6d 29  24 6e e6 55  35 e3 c5 b2  c2 bb 3d     Y.m)$n.U5.....=               218.1.2752

end

def send_ramdisk_and_kernel(ipsw_info)

  dev = AppleDevice.new
  dev.open

  send_ticket()
  send_apple_logo(dev, ipsw_info[:file_applelog])
  send_ramdisk(dev, ipsw_info[:file_ramdisk])
  send_device_tree(dev, ipsw_info[:file_devicetree])
  send_kernel_cache(dev, ipsw_info[:file_kernelcache])

  p "booting"
  dev.send_command("bootx")

  dev.close()
  p "sleeping"
end

def enter_restore(ipsw_info)
  send_ibec(ipsw_info[:file_ibec])
  send_ramdisk_and_kernel(ipsw_info)
end

if __FILE__ == $0
  ipsw_info = get_ipsw_info("m68ap", "ios3_1_3")
  unzip_ipsw ipsw_info
  enter_restore ipsw_info
end