#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require "Win32API"

#static const GUID GUID_DEVINTERFACE_IBOOT = {0xED82A167L, 0xD61A, 0x4AF6, {0x9A, 0xB6, 0x11, 0xE5, 0x22, 0x36, 0xC5, 0x76}};
#static const GUID GUID_DEVINTERFACE_DFU = {0xB8085869L, 0xFEB9, 0x404B, {0x8C, 0xB1, 0x1E, 0x5C, 0x14, 0xFA, 0x8C, 0x54}};

#GENERIC_READ    = 0x80000000
#GENERIC_WRITE   = 0x40000000
#GENERIC_EXECUTE = 0x20000000
#
#FILE_SHARE_READ  = 0x00000001
#FILE_SHARE_WRITE = 0x00000002
#OPEN_EXISTING    = 0x00000003
#FILE_FLAG_OVERLAPPED          = 0x40000000

class Win32Device

  def initialize
    #@path = '\??\USB#Vid_05ac&Pid_1281#CPID:8920_CPRV:15_CPFM:03_SCEP:04_BDID:00_ECID:000000143A045D0C_IBFL:00_SRNM:[889437758M8]_IMEI:[012037007915703]#{a5dcbf10-6530-11d2-901f-00c04fb951ed}'
    @path = '\??\USB#Vid_05ac&Pid_1281#CPID:8920_CPRV:15_CPFM:03_SCEP:04_BDID:00_ECID:000000143A045D0C_IBFL:01_SRNM:[889437758M8]_IMEI:[012037007915703]#{a5dcbf10-6530-11d2-901f-00c04fb951ed}'

    @createFile = Win32API.new('kernel32', 'CreateFile', 'PLLPLLL', 'L')
    @deviceIoControl = Win32API.new('kernel32', 'DeviceIoControl', 'LLPLPLPP', 'I')
    @closeHandle = Win32API.new("kernel32", "CloseHandle", ["L"], 'L')

    @createEvent = Win32API.new('kernel32', 'CreateEvent', 'PIIP', 'L')
    @getOverlappedResult = Win32API.new('kernel32', 'GetOverlappedResult', 'LPPI', 'I')
    @waitForSingleObject = Win32API.new('kernel32', 'WaitForSingleObject', 'LL', 'L')
    @cancelIo = Win32API.new("kernel32", "CancelIo", 'L', 'L')
  end

  def open
    @h = @createFile.call(@path, 0xc0000000, 0x3, 0, 0x3, 0x40000000, 0)
  end

  #@device.controlTransfer(:bmRequestType => 0x40, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataOut => command + "\0")
  #size = @device.controlTransfer(:bmRequestType => 0xC0, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataIn => receive_buffer, :timeout => 0)
  def controlTransfer(params)
    puts params
    event = @createEvent.Call(0, 0, 0, 0)
    overlapped = [0, 0, 0, 0, event].pack("L*")
    packet = [params[:bmRequestType], params[:bRequest], params[:wValue], params[:wIndex]].pack("CCSS")
    if params.has_key?(:dataOut) then
      dataOut = params[:dataOut]
      packet += [dataOut.size, dataOut].pack("L*")
    end
    bytes = 0
    if params.has_key?(:dataIn) then
      dataIn = params[:dataIn]
      outbuf = dataIn
    else
      outbuf = packet
    end
    @deviceIoControl.call(@h, 0x2200A0, packet, packet.size, outbuf, outbuf.size, bytes, overlapped)
    @waitForSingleObject.call(event, params[:timeout])
    res = @getOverlappedResult.Call(@h, overlapped, bytes, 1)
    @closeHandle.call(@h)
    bytes
  end

  def bulkTransfer(params)
    puts params;
    bytes = 0
    ret = @deviceIoControl.call(@h, 0x220195, data, data.size, data, data.size, bytes, 0)
    return ret == 0 ? -1 : 0;
  end

  def reset
    count = 0;
    @deviceIoControl.call(@h, 0x22000C, 0, 0, 0, 0, count, 0);
  end

  def close
    @closeHandle.call(@h)
    @h = nil
  end
end