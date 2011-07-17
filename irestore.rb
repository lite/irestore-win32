#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'iservice'
require 'ipsw_ext'

class RestoreService < PropertyListService
  handle "com.apple.mobile.restored"
  
  def reboot
    request("Reboot")
  end
  
  def start_restore(progress_callback = nil, &data_request_handler)
    # write_plist("Request" => "StartRestore", "RestoreProtocolVersion" => 11)
    write_plist("Request" => "StartRestore", "RestoreProtocolVersion" => 12)
    p "wrote plist"
    while plist = read_plist do
      p "got plist"
      p plist
      
      if plist["MsgType"] =="DataRequestMsg"
        response = data_request_handler.call(plist["DataType"])
        write_plist(response) if response
      elsif progress_callback && plist["MsgType"] == "ProgressMsg" 
        progress_callback.call(plist["Operation"], plist["Progress"])
      elsif plist["MsgType"] == "StatusMsg"
        puts "Got status message: #{plist.inspect}"
        # break if plist["Status"] == 0
        break
      end
    end
  end
  
  def goodbye
    request("Goodbye")
  end
  
  # Valid keys (key cannot be empty):
  #   SerialNumber
  #   IMEI
  #   HardwareModel
  def query_value(key)
    request("QueryValue", "QueryKey" => key)
  end
  
  def query_type
    request("QueryType")
  end
  
  def request(command, hash = {})
    request_plist({"Request" => command}.merge(hash))
  end
end

class ASRService < Service
  def initialize(port, input)
    @socket = USBTCPSocket.new(port)
    
    if input.kind_of?(File)
      @io = input
      @size = input.stat.size
    elsif input.kind_of?(String)
      @io = StringIO.new(input)
      @size = input.size
    end
    
    raise "Unexpected command" unless read_plist["Command"] == "Initiate"
  end
  
  def start
    write_plist({
      "FEC Slice Stride" => 40,
      "Packet Payload Size" => 1450,
      "Packets Per FEC" => 25,
      "Payload" => {
        "Port" => 1,
        "Size" => @size
      },
      "Stream ID" => 1,
      "Version" => 1
    })
    
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
        
        while buffer = @io.read(0x10000) do
          @socket.write(buffer)
          index += 1
          
          if index % 16 == 0
            puts "#{index.to_f / (@size / 0x10000) * 100}% done"
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

def do_restore
  restore = devs[0].open

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

  p "starting restore"
  restore.start_restore(progress_callback) do |data_type|
    puts "DataRequest callback"
  
    if data_type == "SystemImageData"
      puts "Got request for system image data"
    
      Thread.new do
        puts "Started ASR thread" 
        File.open(FILE_RESTOREDMG) do |f|
          # asr = ASRService.new(12345, f)
          asr = ASRService.new(PORT_ASR, f)
          asr.start
        end
      end
    
      nil
    elsif data_type == "NORData"
      puts "Got request for NOR data"
    
      other_nor_data = File.open(FILE_MANIFEST).each_line.reject{|x| x =~ /^LLB/}.map do |line|
        fullpath = File.join(FILE_IMGDIR, line.split("\n")[0])
        StringIO.new(File.open(fullpath).read)
      end

      response = { "LlbImageData" => StringIO.new(File.open(FILE_LLB).read), "NorImageData" => other_nor_data }
      
      response
      
    elsif data_type == "KernelCache"
      puts "Got request for KernelCache data"
      
      response = { "KernelCacheFile" => StringIO.new(File.open(FILE_KERNELCACHE).read)}
      
      response
    end    
  end
  
  p "reboot..."

end


if __FILE__ == $0
  do_restore
end

