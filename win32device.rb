#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require "Win32API"
require "pp"

#static const GUID GUID_DEVINTERFACE_IBOOT = {0xED82A167L, 0xD61A, 0x4AF6, {0x9A, 0xB6, 0x11, 0xE5, 0x22, 0x36, 0xC5, 0x76}};
#static const GUID GUID_DEVINTERFACE_DFU = {0xB8085869L, 0xFEB9, 0x404B, {0x8C, 0xB1, 0x1E, 0x5C, 0x14, 0xFA, 0x8C, 0x54}};

#TRUE = 1
#FALSE = 0

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

    @getLastError = Win32API.new("kernel32", "GetLastError", [], "L")

    @setupDiGetClassDevs = Win32API.new('setupapi', 'SetupDiGetClassDevs', 'PPPL', 'L')
    @setupDiEnumDeviceInterfaces = Win32API.new('setupapi', 'SetupDiEnumDeviceInterfaces', 'LPPLP', 'B')
    @setupDiGetDeviceInterfaceDetail = Win32API.new('setupapi', 'SetupDiGetDeviceInterfaceDetail', 'LPPLPP', 'B')
    @setupDiDestroyDeviceInfoList = Win32API.new('setupapi', 'SetupDiDestroyDeviceInfoList', 'L', 'B')
  end

  def get_dfu
    puts "get_dfu"
    uuid = [0xB8085869, 0xFEB9, 0x404B, 0x8C, 0xB1, 0x1E, 0x5C, 0x14, 0xFA, 0x8C, 0x54].pack('LSSCCCCCCCC')    # DFU
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
      pp "setupDiEnumDeviceInterfaces #{error}, #{idx}"
      break if error == 259
      idx += 1
      required_size = [0x00].pack('L')
      @setupDiGetDeviceInterfaceDetail.call(hdi, spdid, nil, 0, required_size, nil)
      buffer_size = required_size.unpack('L')[0]
      pp "setupDiGetDeviceInterfaceDetail", required_size, buffer_size
      spdidd = [0x5].pack('L') + [0x00].pack('C')*(buffer_size-0x4) # here size must be 0x5
      @setupDiGetDeviceInterfaceDetail.call(hdi, spdid, spdidd, buffer_size, nil, nil)
      pp "setupDiGetDeviceInterfaceDetail #{dev_path}, #{buffer_size}", spdidd
      dev_path = spdidd[4..-1].to_s
    end
    @setupDiDestroyDeviceInfoList.call(hdi)
    dev_path
  end

  def open path
    @h = @createFile.call(path, 0xc0000000, 0x3, 0, 0x3, 0x40000000, 0)
    puts @h
  end

  def send_command(cmd, request=0)
    control_transfer(0x40, request, 0, 0, cmd + "\0")
  end

  def recv_command
    control_transfer(0xc0, 0, 0, 0, nil)
  end

  def print_progress_bar(progress)
      if progress < 0
        return
      elsif progress > 100
        progress = 100
      end
      printf "\r[";
      (0..50).each do |i|
        if(i < progress / 2)
          printf "=";
        else
          printf " " ;
        end
      end
    printf "] #{progress}%%"
      printf "\n"  if progress == 100;
  end

  def send_file(filename)
    total_size = File.stat(filename).size
    packet_size = 0
    File.open(filename, 'r') do |fp|
      while buffer = fp.read(0x800) do
        bulk_transfer(buffer)
        packet_size += buffer.size
        print_progress_bar(packet_size*100/total_size)
      end
    end
    print_progress_bar(100)
  end

  def control_transfer(request_type, request, value, index, in_buffer, timeout=1000)
    packet = [request_type, request, value, index].pack('CCSS')
    out_buffer = "\x00" * 0x400

    case request_type
    when 0x40
      packet += [in_buffer.size].pack('S')
      packet += in_buffer
    when 0xc0
      packet += [out_buffer.size].pack('S')
      packet += out_buffer
    else
      packet += [0x00].pack('S')
    end

    puts "deviceIoControl"
    event = @createEvent.Call(nil, 1, 0, nil)
    overlapped = [0, 0, 0, 0, event].pack("L*")
    bytes_transferred = [0x00].pack('L')
    ctrl_code = 0x2200A0
    @deviceIoControl.call(@h, ctrl_code, packet, packet.size, out_buffer, out_buffer.size, bytes_transferred, overlapped)
    puts "waitForSingleObject"
    @waitForSingleObject.call(event, timeout)
    puts "getOverlappedResult"
    @getOverlappedResult.Call(@h, overlapped, bytes_transferred, 0)
    puts "closeHandle"
    @closeHandle.call(@h)
    transferred = bytes_transferred.unpack('L')[0]
    pp "#{transferred}", out_buffer[0, transferred]
    out_buffer[0, transferred]
  end

  def bulk_transfer(packet)
    bytes_transferred = [0x00].pack('L')
    ctrl_code = 0x2201B6 #0x220003 #0x220195 #0x2201B6
    @deviceIoControl.call(@h, ctrl_code, packet, packet.size, packet, packet.size, bytes_transferred, nil)
    transferred = bytes_transferred.unpack('L')[0]
    pp "#{transferred}"
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
