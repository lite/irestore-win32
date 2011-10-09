#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'win32device'

def test_getdevpath
  dev = Win32Device.new
  dev.get_iboot
end

def test_send_command(cmd, request=0)
  dev = Win32Device.new
  path = dev.get_iboot
  puts path
  dev.open path
  dev.send_command(cmd, request)
  dev.close
end

def test_recv_command
  dev = Win32Device.new
  path = dev.get_iboot
  puts path
  dev.open path
  puts dev.recv_command
  dev.close
end

def test_reboot
  test_send_command "reboot"
end

def test_getenv
  test_send_command "getenv build-version"
end

def test_send_file(filename)
  dev = Win32Device.new
  path = dev.get_iboot
  puts path
  dev.open path
  dev.send_file(filename)
  dev.close
end

def test_read_file
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu'
  File.open(filename) do |f|
    while buffer = f.read(0x800) do
      puts buffer.size
    end
  end
end

def test_control_transfer(request_type, request, value, index, in_buffer, timeout=1000)
  dev = Win32Device.new
  path = dev.get_iboot
  puts path
  dev.open path
  dev.control_transfer(request_type, request, value, index, in_buffer, timeout)
  dev.close
end

def test_set_interface
  dev = Win32Device.new
  path = dev.get_iboot
  puts path
  dev.open path
  dev.control_transfer(0x01, 0x0b, 0, 1, nil)
  dev.close
end

def test_ibec
  test_set_interface

  test_send_command("setenv auto-boot false")
  test_send_command("saveenv")

  test_control_transfer(0x41, 0, 0, 0, nil)

  p "sending iBEC"
  filename = '/home/dli/tools/iOS/ipsw/dmg_new/Firmware/dfu/iBEC.n88ap.RELEASE.dfu'
  test_send_file(filename)

  test_control_transfer(0x40, 0x1, 0, 0, "go\0")
end

if __FILE__ == $0
  #test_getdevpath
  #test_getenv
  #test_recv_command
  #test_reboot
  #test_read_file
  test_ibec
end
