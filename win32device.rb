#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require "Win32API"

GENERIC_READ = 0

OPEN_EXISTING = 0

INVALID_HANDLE_VALUE = -1

class Win32Device

  def initialize(path, options={})
    @path = path
    @options = options
    @createFile = Win32API.new('kernel32', 'CreateFile', 'PLLPLLL', 'L')
    @createFile = Win32API.new("kernel32", "CreateFile",
      ['P', 'L', 'L', 'P', 'L', 'L', 'L'], 'L')
    @h = createFile.call(fn, GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0)
    if @h == INVALID_HANDLE_VALUE
      raise "Open failed"
    end
    @deviceIoControl = Win32API.new('kernel32', 'DeviceIoControl', 'LLPLPLPP', 'I')
    @closeHandle = Win32API.new("kernel32", "CloseHandle", ["L"], 'L')
  end

  def ioctl(code, inbuf, outbuf)
    bytes = 0
    @deviceIoControl.call(@h, code, inbuf, inbuf.size, outbuf, outbuf.size, bytes, 0)
    outbuf[0..count]
  end

  def close
    @closeHandle.call(@h)
    @h = nil
  end
end