#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'iservice'
require 'ipsw_ext'
require 'pp'

class RestoreService < DeviceService

  def start_restore(progress_callback = nil, &data_request_handler)
    obj = {"Request" => "StartRestore", "RestoreProtocolVersion" => 12}
    write_plist(@socket, obj)

    p "wrote plist"
    loop do
      plist = read_plist(@socket)
      p "got plist", plist

      if plist["MsgType"] =="DataRequestMsg"
        response = data_request_handler.call(plist["DataType"])
        write_plist(@socket, response) if response
      elsif progress_callback && plist["MsgType"] == "ProgressMsg"
        progress_callback.call(plist["Operation"], plist["Progress"])
      elsif plist["MsgType"] == "StatusMsg"
        puts "Got status message: #{plist.inspect}"
        # break if plist["Status"] == 0
        break
      end
    end
  end

end

class ASRService < DeviceService

  def start(input)

    p "start ASR."
    @io = input
    @size = input.stat.size

    #<key>Checksum Chunk Size</key><integer>131072</integer>
    #<key>FEC Slice Stride</key><integer>40</integer>
    #<key>Packet Payload Size</key><integer>1450</integer>
    #<key>Packets Per FEC</key><integer>25</integer>
    #<key>Payload</key><dict>
    #<key>Port</key><integer>1</integer>
    #<key>Size</key><integer>677601280</integer></dict>
    #<key>Stream ID</key><integer>1</integer>
    #<key>Version</key><integer>1</integer>
    obj ={
        "Checksum Chunk Size" => 131072,
        "FEC Slice Stride" => 40,
        "Packet Payload Size" => 1450,
        "Packets Per FEC" => 25,
        "Payload" => {
            "Port" => 1,
            "Size" => @size
        },
        "Stream ID" => 1,
        "Version" => 1
    }

    write_plist(obj)

    while plist = read_plist do
      if plist["Command"] == "OOBData"
        size = plist["OOB Length"]
        offset = plist["OOB Offset"]

        puts "Sending #{size} OOB bytes from offset #{offset}"

        @io.seek(offset)
        @socket.write(@io.read(size))
      elsif plist["Command"] == "Payload"
        puts "Sending payload"
        @io.seek(0)

        index = 0
        packet_len = 0x10000
        while buffer = @io.read(packet_len) do
          @socket.write(buffer)
          index += 1

          if index % 20 == 0
            puts "%.2f%% done" % (index.to_f / (@size / packet_len) * 100)
          end
        end
        break
      else
        puts "Unknown ASR command #{plist.inspect}"
      end
    end
  end

  def read_plist
    buffer = ""

    while read_buffer = @socket.gets do
      puts "Read: #{read_buffer.inspect}"
      buffer << read_buffer
      break if read_buffer =~ /<\/plist>/
    end

    PropertyList.load(buffer)
  end

  def write_plist(obj)
    payload = PropertyList.dump(obj, :xml1)
    @socket.write(payload)
  end

end

#define WAIT_FOR_STORAGE       11
#define CREATE_PARTITION_MAP   12
#define CREATE_FILESYSTEM      13
#define RESTORE_IMAGE          14
#define VERIFY_RESTORE         15
#define CHECK_FILESYSTEM       16
#define MOUNT_FILESYSTEM       17
#define FLASH_NOR              19
#define UPDATE_BASEBAND        20
#define FINIALIZE_NAND         21
#define MODIFY_BOOTARGS        26
#define LOAD_KERNEL_CACHE      27
#define PARTITION_NAND_DEVICE  28
#define WAIT_FOR_NAND          29
#define UNMOUNT_FILESYSTEM     30
#define WAIT_FOR_DEVICE        33
#define LOAD_NOR               36

def do_restore ipsw_info
  progress_callback = proc do |operation, progress|
    steps = {
        11 => "Waiting for storage device",
        12 => "Creating partition map",
        13 => "Creating filesystem",
        14 => "Restoring image",
        15 => "Verifying restore",
        16 => "Checking filesystems",
        17 => "Mounting filesystems",
        19 => "Flashing NOR",
        20 => "Updating baseband",
        21 => "Finalizing NAND epoch update",
        26 => "Modifying persistent boot-args",
        27 => "Unmounting filesystems",
        28 => "Partition NAND device",
        29 => "Waiting for NAND",
        30 => "Waiting for device",
        33 => "Loading kernelcache",
        36 => "Loading NOR data to flash",
        # return "Unknown operation";
    }
    puts "#{steps[operation]} (#{operation}) with progress #{progress}"
  end

  restore = RestoreService.new(PORT_RESTORE)

  p "starting restore"
  restore.start_restore(progress_callback) do |data_type|
    puts "DataRequest callback"

    if data_type == "SystemImageData"
      puts "Got request for system image data"

      Thread.new do
        puts "Started ASR thread"
        puts ipsw_info
        File.open(ipsw_info[:file_restoredmg]) do |f|
          asr = ASRService.new(PORT_ASR)
          asr.start(f)
        end
      end

      nil
    elsif data_type == "NORData"
      puts "Got request for NOR data"

      other_nor_data = File.open(ipsw_info[:file_manifest]).each_line.reject { |x| x =~ /^LLB/ }.map do |line|
        fullpath = File.join(ipsw_info[:file_imgdir], line.split("\n")[0])
        nor_data = File.open(fullpath).read
        nor_data.blob = true
        nor_data
      end

      llb_data = File.open(ipsw_info[:file_llb]).read
      llb_data.blob = true
      response = {"LlbImageData" => llb_data, "NorImageData" => other_nor_data}
      response
    elsif data_type == "KernelCache"
      puts "Got request for KernelCache data"

      kernel_data = File.open(ipsw_info[:file_kernelcache]).read
      kernel_data.blob = true
      response = {"KernelCacheFile" => kernel_data}
      response
    elsif data_type == "RootTicket"
      puts "Got request for RootTicket data"

      root_ticket_data = File.open(ipsw_info[:file_ap_ticket]).read
      root_ticket_data.blob = true
      response = {"RootTicketData" => root_ticket_data}
      response
    end
  end

  p "reboot..."

end


if __FILE__ == $0
  ipsw_info = get_ipsw_info("n88ap", "ios5_0")
  #ipsw_info = get_ipsw_info("m68ap", "ios3_1_3")
  do_restore ipsw_info
end
