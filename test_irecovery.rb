#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'irecovery'
require 'ipsw_ext'

def run_irecovery command
  @d = IRecovery.new
  @d.send_command command
end

def irecovery_file path
  @d = IRecovery.new
  @d.send_file path
end

def test_irecovery
  run_irecovery("-c reboot")

  irecovery_file(FILE_IBEC)
  run_irecovery("-c setenv auto-boot false")
  run_irecovery("-c saveenv")
  run_irecovery("-c go")
end

def test
  message = "This is a sample Windows message box generated using Win32API"
  title = "Win32API from Ruby"

  api = Win32API.new('user32','MessageBox',['L', 'P', 'P', 'L'],'I')
  api.call(0,message,title,0)
end

if __FILE__ == $0
  test
  test_irecovery
end

