#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'win32device'

def test_getdevpath
  dev = Win32Device.new
  dev.get_devpath
end

def test_send_command(cmd)
  dev = Win32Device.new
  path = dev.get_devpath
  puts path
  dev.open path
  #send
  dev.controlTransfer(:bmRequestType => 0x40, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataOut => cmd)
  #recv
  receive_buffer = "\x00" * 0x10
  size = @device.controlTransfer(:bmRequestType => 0xC0, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataIn => receive_buffer)
  puts size,receive_buffer[0, size]
  dev.close
end

def test_getenv
  test_send_command "getenv build-version\0"
end

def test_reboot
  test_send_command "reboot\0"
end

if __FILE__ == $0
  #test_getdevpath
  #test_getenv
  test_reboot
end
