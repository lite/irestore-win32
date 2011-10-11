#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require "Win32API"

#static const GUID GUID_DEVINTERFACE_IBOOT = {0xED82A167L, 0xD61A, 0x4AF6, {0x9A, 0xB6, 0x11, 0xE5, 0x22, 0x36, 0xC5, 0x76}};
#static const GUID GUID_DEVINTERFACE_DFU = {0xB8085869L, 0xFEB9, 0x404B, {0x8C, 0xB1, 0x1E, 0x5C, 0x14, 0xFA, 0x8C, 0x54}};

#TRUE = 1
#FALSE = 0

#INFINITE = 0xFFFFFFFF

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
    @createFile = Win32API.new('kernel32', 'CreateFile', 'PLLPLLP', 'L')
    @deviceIoControl = Win32API.new('kernel32', 'DeviceIoControl', 'LLPLPLPP', 'I')
    @closeHandle = Win32API.new("kernel32", "CloseHandle", 'L', 'L')

    @createEvent = Win32API.new('kernel32', 'CreateEvent', 'PLLP', 'L')
    @getOverlappedResult = Win32API.new('kernel32', 'GetOverlappedResult', 'LPPL', 'L')
    @waitForSingleObject = Win32API.new('kernel32', 'WaitForSingleObject', 'LL', 'L')
    @cancelIo = Win32API.new("kernel32", "CancelIo", 'L', 'L')

    @sleep = Win32API.new('kernel32', 'Sleep', 'L', 'L')
    @getLastError = Win32API.new("kernel32", "GetLastError", '', "L")

    @setupDiGetClassDevs = Win32API.new('setupapi', 'SetupDiGetClassDevs', 'PPPL', 'L')
    @setupDiEnumDeviceInterfaces = Win32API.new('setupapi', 'SetupDiEnumDeviceInterfaces', 'LPPLP', 'B')
    @setupDiGetDeviceInterfaceDetail = Win32API.new('setupapi', 'SetupDiGetDeviceInterfaceDetail', 'LPPLPP', 'B')
    @setupDiDestroyDeviceInfoList = Win32API.new('setupapi', 'SetupDiDestroyDeviceInfoList', 'L', 'B')
  end

  def sleep(seconds)
    @sleep.call(seconds*1000)
  end

  def open(path=nil)
    path = get_iboot if path.nil?
    puts path
    3.times do
      #@h = @createFile.call(path, 0xc0000000, 0, nil, 0x3, 0x40000000, 0)
      @h = @createFile.call(path, 0xc0000000, 0, nil, 0x3, 0, nil)
      break if @h > 0
      puts "wait for reboot"
      sleep(5)
    end

    set_interface(1, 0)
    sleep(1)
    @h
  end

  def close
    puts "open", @h
    @closeHandle.call(@h)
  end

  def get_dfu
    uuid = [0xB8085869, 0xFEB9, 0x404B, 0x8C, 0xB1, 0x1E, 0x5C, 0x14, 0xFA, 0x8C, 0x54].pack('LSSCCCCCCCC') # DFU
    get_devpath(uuid)
  end

  def get_iboot
    uuid = [0xED82A167, 0xD61A, 0x4AF6, 0x9A, 0xB6, 0x11, 0xE5, 0x22, 0x36, 0xC5, 0x76].pack('LSSCCCCCCCC') # iBoot
    get_devpath(uuid)
  end

  def get_devpath(uuid)
    dev_path = ""

    hdi = @setupDiGetClassDevs.call(uuid, nil, nil, 0x12)
    idx = 0
    loop do
      spdid = [0x18+0x4].pack('L')+[0x00].pack('C')*0x18
      @setupDiEnumDeviceInterfaces.call(hdi, nil, uuid, idx, spdid)
      error = @getLastError.call()
      break if error == 259
      idx += 1
      required_size = [0x00].pack('L')
      @setupDiGetDeviceInterfaceDetail.call(hdi, spdid, nil, 0, required_size, nil)
      buffer_size = required_size.unpack('L')[0]
      spdidd = [0x5].pack('L') + [0x00].pack('C')*(buffer_size-0x4) # here size must be 0x5
      @setupDiGetDeviceInterfaceDetail.call(hdi, spdid, spdidd, buffer_size, nil, nil)
      dev_path = spdidd[4..-1].to_s
    end
    @setupDiDestroyDeviceInfoList.call(hdi)
    dev_path
  end

  def send_command(cmd, request=0)
    packet = [0x40, request, 0, 0, cmd.size+1].pack('CCSSS')
    packet += "#{cmd}\0"

    control_io(cmd.size, packet)
  end

  def recv_command(length=0x400)
    packet = [0xc0, 0, 0, 0, length].pack('CCSSS')
    packet += "\0"*length

    transferred = control_io(length, packet)

    packet[0, transferred]
  end

  def send_file(filename)
    control_transfer(0x41, 0, 0, 0, 0)
    sleep(1)
    total_size = File.stat(filename).size
    packet_size = 0
    File.open(filename, 'r') do |fp|
      while buffer = fp.read(0x8000) do
        bulk_transfer(buffer)
        ack
        packet_size += buffer.size
        puts "#{packet_size}/#{total_size}"
      end
    end
  end

  def reset
    bytes_transferred = [0x00].pack('L')
    @deviceIoControl.call(@h, 0x22000C, nil, 0, nil, 0, bytes_transferred, nil)
  end

  def ack
    packet = [0x00].pack('L')
    bytes_transferred = [0x00].pack('L')
    @deviceIoControl.call(@h, 0x2200B8, packet, packet.size, packet, packet.size, bytes_transferred, nil);
    packet.unpack('L')[0]
  end

  def set_config(config)
    #00 09 01 00  00 00 00 00
    control_transfer(0x00, 0x09, config, 0, 0)
  end

  def set_interface(interface, alt_setting)
    #01 0b 00 00  01 00 00 00
    control_transfer(0x01, 0x0b, alt_setting, interface, 0)
  end

  def control_transfer(request_type, request, value, index, length)
    packet = [request_type, request, value, index, length].pack('CCSSS')
    packet += "\x00" * length if length > 0

    control_io(length, packet)
  end

  def control_io(length, packet)
    bytes_transferred = [0x00].pack('L')
    @deviceIoControl.call(@h, 0x2200A0, packet, packet.size, packet, packet.size, bytes_transferred, nil)
    bytes_transferred.unpack('L')[0]
  end

  def bulk_transfer(packet)
    # sig_send: wait for sig_complete event failed, signal 6, rc 258, win32 error 0
    bytes_transferred = [0x00].pack('L')
    #0x220003 #0x220195 #0x2201B6
    @deviceIoControl.call(@h, 0x2201B6, packet, packet.size, packet, packet.size, bytes_transferred, nil)
    bytes_transferred.unpack('L')[0]
  end

  # not used
  #def control_io_async(length, packet, timeout=1000)
  #  event = @createEvent.Call(nil, 1, 0, nil)
  #  overlapped = [0, 0, 0, 0, event].pack("L*")
  #  bytes_transferred = [0x00].pack('L')
  #  @deviceIoControl.call(@h, 0x2200A0, packet, packet.size, packet, packet.size, bytes_transferred, overlapped)
  #  @waitForSingleObject.call(event, timeout)
  #  ret = @getOverlappedResult.Call(@h, overlapped, bytes_transferred, 0)
  #  @closeHandle.call(event)
  #  puts ret
  #  @cancelIo.call(@h) unless ret == 1
  #  puts "cancelIo" unless ret == 1
  #
  #  bytes_transferred.unpack('L')[0]
  #end

  #def bulk_transfer_async(packet, timeout=1000)
  #  event = @createEvent.Call(nil, 1, 0, nil)
  #  overlapped = [0, 0, 0, 0, event].pack("L*")
  #  bytes_transferred = [0x00].pack('L')
  #  @deviceIoControl.call(@h, 0x220195, packet, packet.size, packet, packet.size, bytes_transferred, overlapped)
  #  @waitForSingleObject.call(event, timeout)
  #  ret = @getOverlappedResult.Call(@h, overlapped, bytes_transferred, 0)
  #  @closeHandle.call(event)
  #  puts ret
  #  @cancelIo.call(@h) unless ret == 1
  #  puts "cancelIo" unless ret == 1
  #
  #  bytes_transferred.unpack('L')[0]
  #end

end
