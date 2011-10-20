#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'win32device'
require 'ipsw_ext'

def test_getdevpath
  dev = Win32Device.new
  puts dev.get_iboot
  puts dev.get_dfu
end

def test_reboot
  dev = Win32Device.new
  dev.open
  dev.send_command "reboot"
  dev.close
end

def test_return_normal_mode
  dev = Win32Device.new
  dev.open
  dev.send_command "setenv auto-boot true"
  dev.send_command "saveenv"
  dev.send_command "reboot"
  dev.close
end

def test_getenv
  dev = Win32Device.new
  dev.open
  cmd = "getenv build-version"
  dev.send_command(cmd)
  puts dev.recv_command
  dev.close
end

def test_set_interface
  dev = Win32Device.new
  dev.open
  dev.set_interface(1, 0)
  dev.close
end

def test_sleep
  dev = Win32Device.new
  puts Time.now
  dev.sleep(3)
  puts Time.now
end

def test_ibec(filename)
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
end

def test_enter_mode(ipsw_info)
  test_ticket
  test_applogo(ipsw_info[:file_applelog])
  test_ramdisk(ipsw_info[:file_ramdisk])
  test_devicetree(ipsw_info[:file_devicetree])
  test_kernel(ipsw_info[:file_kernelcache])
end

def test_ticket
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

def test_applogo(filename)
  dev = Win32Device.new
  dev.open

  dev.send_command("setenv auto-boot false")
  dev.send_command("saveenv")

  p "sending apple logo"
  puts filename
  dev.send_file(filename)

  dev.send_command("setpicture 0")
  dev.send_command("bgcolor 0 0 0")

  dev.reset
  dev.close
end

def test_ramdisk(filename)
  dev = Win32Device.new
  dev.open

  p "sending ramdisk"
  puts filename
  dev.send_file(filename)

  dev.send_command("ramdisk")

  dev.reset
  dev.close
end

def test_devicetree(filename)
  dev = Win32Device.new
  dev.open

  p "sending device tree"
  puts filename
  dev.send_file(filename)

  dev.send_command("devicetree")

  dev.reset
  dev.close
end

def test_kernel(filename)
  dev = Win32Device.new
  dev.open

  p "sending kernel"
  puts filename
  dev.send_file(filename)

  p "booting"
  dev.send_command("setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
  dev.send_command("bootx", 0x1)

  dev.reset
  dev.close
end

if __FILE__ == $0
  #ipsw_info = get_ipsw_info("m68ap", "ios3_1_3")
  ipsw_info = get_ipsw_info("n88ap", "ios5_0")
  unzip_ipsw ipsw_info
  #test_sleep
  #test_return_normal_mode
  test_reboot
  #test_getdevpath
  #test_set_interface
  #test_getenv
  #test_ibec(ipsw_info[:file_ibec])
  #test_enter_mode(ipsw_info)
end
