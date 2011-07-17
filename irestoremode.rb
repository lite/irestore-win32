#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ipsw_ext'
require 'Open3'

PATH_IRECOVERY = File.join(File.dirname(__FILE__), "s-irecovery.exe");

def run_irecovery(args)
  cmd = [PATH_IRECOVERY, args].join(" ")
  Open3.popen3(cmd) { |i,o,e,t| puts o.read }
end

def enter_restore
  run_irecovery("-c getenv build-version")
  run_irecovery("-c getenv build-style")
  run_irecovery("-c setenv auto-boot false")
  run_irecovery("-c setenv saveenv")

  p "sending iBEC"
  run_irecovery("-f #{FILE_IBEC}")

  run_irecovery("-c setenv auto-boot false")
  run_irecovery("-c setenv saveenv")
  run_irecovery("-c go")
  
  sleep(5)
  
  p "sending apple logo"
  run_irecovery("-f #{FILE_APPLELOG}")
  run_irecovery("-c setpicture 0")
  run_irecovery("-c bgcolor 0 0 0")
 
  p "sending ramdisk"
  run_irecovery("-f #{FILE_RAMDISK}")
  run_irecovery("-c ramdisk")
 
  p "sending device tree"
  run_irecovery("-f #{FILE_DEVICETREE}")
  run_irecovery("-c devicetree")

  p "sending kernel and booting"
  run_irecovery("-f #{FILE_KERNELCACHE}")
  run_irecovery("-c setenv boot-args rd=md0 nand-enable-reformat=1 -progress")
  run_irecovery("-c bootx")
  
  sleep(10)
end

if __FILE__ == $0
  enter_restore
end