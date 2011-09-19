#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ipsw_ext'
require 'Open3'
#require 'win32/open3'

def run_irecovery(args)
  cmd = [PATH_IRECOVERY, args].join(" ")
  p cmd
  # Open3.popen3(cmd) { |i,o,e,t| puts o.read }
  Open3.popen3(cmd) do |io_in, io_out, io_err|
    while line = io_out.gets
      print ":", line
    end
  end
end

def irecovery_file(unix_path)
  #cygpath -w /home/dli/tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu
  args = "-f `cygpath -w #{unix_path}` "
  run_irecovery(args)
end
 
def enter_restore
  #run_irecovery("-c reboot")
  
  run_irecovery("-c getenv build-version")
  run_irecovery("-c getenv build-style")
  run_irecovery("-c setenv auto-boot false")
  run_irecovery("-c saveenv'")

  p "sending iBEC"
  run_irecovery("-r")
  # run_irecovery("-f #{FILE_IBEC}")  # not working, for s-irecovery only accept windows path, not unix path
  irecovery_file(FILE_IBEC)
  run_irecovery("-c setenv auto-boot false")
  run_irecovery("-c saveenv")
  run_irecovery("-c go")
  
  p "sleeping"
  sleep(10)
  
  p "sending apple logo"
  run_irecovery("-r")
  irecovery_file(FILE_APPLELOG)
  run_irecovery("-c setpicture 0")
  # run_irecovery("-c bgcolor 0 0 0")
  run_irecovery("-c 'bgcolor 0 255 0'")
  
  p "sending ramdisk"
  run_irecovery("-r")
  irecovery_file(FILE_RAMDISK)
  run_irecovery("-c ramdisk")
   
  p "sending device tree"
  run_irecovery("-r")
  irecovery_file(FILE_DEVICETREE)
  run_irecovery("-c devicetree")
  
  p "sending kernel and booting"
  run_irecovery("-r")
  irecovery_file(FILE_KERNELCACHE)
  run_irecovery("-c setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
  run_irecovery("-c bootx")
  
  p "sleeping"
  sleep(10)
end

if __FILE__ == $0
  enter_restore
end