#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require "Win32API"
require "pp"

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

#DIGCF_PRESENT = 0x00000002
#DIGCF_DEVICEINTERFACE = 0x00000010

#ERROR_DISK_FULL = 112;
#ERROR_NO_MORE_ITEMS = 259
#ERROR_INVALID_USER_BUFFER = 1784

class Win32Device

  def initialize
    @createFile = Win32API.new('kernel32', 'CreateFile', 'PLLPLLL', 'L')
    @deviceIoControl = Win32API.new('kernel32', 'DeviceIoControl', 'LLPLPLPP', 'I')
    @closeHandle = Win32API.new("kernel32", "CloseHandle", ["L"], 'L')

    @createEvent = Win32API.new('kernel32', 'CreateEvent', 'PIIP', 'L')
    @getOverlappedResult = Win32API.new('kernel32', 'GetOverlappedResult', 'LPPI', 'I')
    @waitForSingleObject = Win32API.new('kernel32', 'WaitForSingleObject', 'LL', 'L')
    @cancelIo = Win32API.new("kernel32", "CancelIo", 'L', 'L')

    @getLastError = Win32API.new("kernel32","GetLastError",[],"L")

    @setupDiGetClassDevs = Win32API.new('setupapi', 'SetupDiGetClassDevs', 'PPPL', 'L')
    @setupDiEnumDeviceInterfaces = Win32API.new('setupapi', 'SetupDiEnumDeviceInterfaces', 'LPPLP', 'B')
    @setupDiGetDeviceInterfaceDetail = Win32API.new('setupapi', 'SetupDiGetDeviceInterfaceDetail', 'LPPLPP', 'B')
    @setupDiDestroyDeviceInfoList = Win32API.new('setupapi', 'SetupDiDestroyDeviceInfoList', 'L', 'B')
  end

  def get_devpath;
    dev_path = ""

    #uuid = [0xB8085869, 0xFEB9, 0x404B, 0x8C, 0xB1, 0x1E, 0x5C, 0x14, 0xFA, 0x8C, 0x54].pack('LSSCCCCCCCC')    # DFU
    uuid = [0xED82A167, 0xD61A, 0x4AF6, 0x9A, 0xB6, 0x11, 0xE5, 0x22, 0x36, 0xC5, 0x76].pack('LSSCCCCCCCC')   # iBoot
    hdi = @setupDiGetClassDevs.call(uuid, nil, nil, 0x12)
    idx = 0
    loop do
      spdid = [0x18+0x4].pack('L')+[0x00].pack('C')*0x18
      @setupDiEnumDeviceInterfaces.call(hdi, nil, uuid, idx, spdid)
      error = @getLastError.call()
      pp  "setupDiEnumDeviceInterfaces #{error}, #{idx}"
      break if error == 259
      idx += 1
      required_size = [0x00].pack('L')
      @setupDiGetDeviceInterfaceDetail.call(hdi, spdid, nil, 0, required_size, nil)
      buffer_size = required_size.unpack('L')[0]
      pp  "setupDiGetDeviceInterfaceDetail", required_size, buffer_size
      spdidd = [0x5].pack('L') + [0x00].pack('C')*(buffer_size-0x4)  # here size must be 0x5
      @setupDiGetDeviceInterfaceDetail.call(hdi, spdid, spdidd, buffer_size, nil, nil)
      pp  "setupDiGetDeviceInterfaceDetail #{dev_path}, #{buffer_size}",spdidd
      dev_path = spdidd[4..-1].to_s
    end
    @setupDiDestroyDeviceInfoList.call(hdi)
    dev_path
  end

  def open path
    @h = @createFile.call(path, 0xc0000000, 0x3, 0, 0x3, 0x40000000, 0)
    puts @h
  end

  #@device.controlTransfer(:bmRequestType => 0x40, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataOut => command + "\0")
  #size = @device.controlTransfer(:bmRequestType => 0xC0, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataIn => receive_buffer, :timeout => 0)
  def controlTransfer(params)
    puts params
    event = @createEvent.Call(0, 0, 0, 0)
    overlapped = [0, 0, 0, 0, event].pack("L*")
    packet = [params[:bmRequestType], params[:bRequest], params[:wValue], params[:wIndex]].pack('CCSS')
    if params.has_key?(:dataOut) then
      dataOut = params[:dataOut]
      packet += [dataOut.size].pack('S')
      packet += dataOut
    end
    pp packet
    bytes = 0
    if params.has_key?(:dataIn) then
      dataIn = params[:dataIn]
      outbuf = dataIn
    else
      outbuf = packet
    end
    if params.has_key?(:timeout) then
      timeout = params[:timeout]
    else
      timeout = 1000
    end
    @deviceIoControl.call(@h, 0x2200A0, packet, packet.size, outbuf, outbuf.size, bytes, overlapped)
    @waitForSingleObject.call(event, timeout)
    @getOverlappedResult.Call(@h, overlapped, bytes, 1)
    @closeHandle.call(@h)
    pp "#{bytes}", outbuf
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
