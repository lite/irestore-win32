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
    @closeHandle = Win32API.new("kernel32", "CloseHandle", ["L"], 'L')

    @createEvent = Win32API.new('kernel32', 'CreateEvent', 'PLLP', 'L')
    @getOverlappedResult = Win32API.new('kernel32', 'GetOverlappedResult', 'LPPL', 'L')
    @waitForSingleObject = Win32API.new('kernel32', 'WaitForSingleObject', 'LL', 'L')
    @cancelIo = Win32API.new("kernel32", "CancelIo", 'L', 'L')

    @getLastError = Win32API.new("kernel32", "GetLastError", [], "L")

    @setupDiGetClassDevs = Win32API.new('setupapi', 'SetupDiGetClassDevs', 'PPPL', 'L')
    @setupDiEnumDeviceInterfaces = Win32API.new('setupapi', 'SetupDiEnumDeviceInterfaces', 'LPPLP', 'B')
    @setupDiGetDeviceInterfaceDetail = Win32API.new('setupapi', 'SetupDiGetDeviceInterfaceDetail', 'LPPLPP', 'B')
    @setupDiDestroyDeviceInfoList = Win32API.new('setupapi', 'SetupDiDestroyDeviceInfoList', 'L', 'B')
  end

  def close
    @closeHandle.call(@h)
    @h = nil
  end

  def open
    path = get_iboot
    @h = @createFile.call(path, 0xc0000000, 0x3, nil, 0x3, 0x40000000, 0)
    #@h = @createFile.call(path, 0xc0000000, 0, nil, 0x3, 0, nil)
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
    control_command(0x40, request, 0, 0, cmd + "\0")
  end

  def recv_command
    control_transfer(0xc0, 0, 0, 0, 0x400)
  end

  def send_file(filename)
    control_transfer(0x41, 0, 0, 0, 0)

    total_size = File.stat(filename).size
    packet_size = 0
    File.open(filename, 'r') do |fp|
      while buffer = fp.read(0x2000) do
        bulk_transfer(buffer)
        packet_size += buffer.size
        print_progress_bar(packet_size*100/total_size)
      end
    end
    print_progress_bar(100)
  end

  def reset
    bytes_transferred = [0x00].pack('L')
    @deviceIoControl.call(@h, 0x22000C, nil, 0, nil, 0, bytes_transferred, nil);
  end

  def init
    #40 00 00 00  00 00 13 00
    control_transfer(0x40, 0, 0, 0, 0x13)
  end

  def set_config(config)
    #00 09 01 00  00 00 00 00
    control_transfer(0x00, 0x09, config, 0, 0)
  end

  def set_interface(interface, alt_setting)
    #01 0b 00 00  01 00 00 00
    control_transfer(0x01, 0x0b, alt_setting, interface, 0)
  end

  def control_command(request_type, request, value, index, in_buffer=nil)
    packet = [request_type, request, value, index, in_buffer.size].pack('CCSSS')
    packet += in_buffer

    control_io(in_buffer.size, packet)
  end

  def control_transfer(request_type, request, value, index, length)
    packet = [request_type, request, value, index, length].pack('CCSSS')
    packet += "\x00" * length if length > 0

    control_io(length, packet)
  end

  def control_io(length, packet)
    control_io_overlapped(length, packet)
    return
    out_buffer = "\0"*length
    bytes_transferred = [0x00].pack('L')
    @deviceIoControl.call(@h, 0x2200A0, packet, packet.size, out_buffer, out_buffer.size, bytes_transferred, nil)
    transferred = bytes_transferred.unpack('L')[0]
    out_buffer[0, transferred]
  end

  def control_io_overlapped(length, packet, timeout=1000)
    out_buffer = "\0"*length
    event = @createEvent.Call(nil, 1, 0, nil)
    overlapped = [0, 0, 0, 0, event].pack("L*")
    bytes_transferred = [0x00].pack('L')
    @deviceIoControl.call(@h, 0x2200A0, packet, packet.size, out_buffer, out_buffer.size, bytes_transferred, overlapped)
    @waitForSingleObject.call(event, timeout)
    ret = @getOverlappedResult.Call(@h, overlapped, bytes_transferred, 0)
    @closeHandle.call(event)
    @cancelIo.call(@h) unless ret
    puts "cancelIo" unless ret

    transferred = bytes_transferred.unpack('L')[0]
    out_buffer[0, transferred]
  end

  def bulk_transfer(packet)
    bytes_transferred = [0x00].pack('L')
    #0x220003 #0x220195 #0x2201B6
    @deviceIoControl.call(@h, 0x2201B6, packet, packet.size, packet, packet.size, bytes_transferred, nil)
    bytes_transferred.unpack('L')[0]
  end

  private
  def print_progress_bar(progress)
    if progress < 0
      return
    elsif progress > 100
      progress = 100
    end
    printf "\r[";
    (0..50).each do |i|
      if (i < progress / 2)
        printf "=";
      else
        printf " ";
      end
    end
    printf "] #{progress}%%"
    printf "\n" if progress == 100;
  end

end
