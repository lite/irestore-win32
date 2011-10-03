#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'ipsw_ext'
require 'irecovery'

$dev = IRecoveryDevice.new

def send_ibec
  x = $dev.open

  x.send_command("getenv build-version")
  p x.recv_command.split("\x00")
 
  res = x.send_command("getenv build-style")
  p x.recv_command.split("\x00")

  x.send_command("setenv auto-boot false")
  x.send_command("saveenv")

  p "sending iBEC"
  x.send_file(FILE_IBEC)
  
  x.send_command("setenv auto-boot false")
  x.send_command("saveenv")
  x.send_command("go")

  x.close

  sleep(10)
end

def send_ramdisk
  x = $dev.open

  p "sending apple logo"

  x.send_file(FILE_APPLELOG)
  
  x.send_command("setpicture 0")
  x.send_command("bgcolor 0 0 0")

  p "sending ramdisk"
  x.send_file(FILE_RAMDISK)
  
  x.send_command("ramdisk")

  p "sending device tree"
  x.send_file(FILE_DEVICETREE)

  x.send_command("devicetree")

  p "sending kernel"
  x.send_file(FILE_KERNELCACHE)
  
  p "booting"
  x.send_command("setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
  x.send_command("bootx")

  x.close()
  p "sleeping"
  sleep(10)

end

def enter_restore
  send_ibec
  send_ramdisk
end

if __FILE__ == $0
  enter_restore
end