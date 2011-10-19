#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'iservice'
require 'openssl'
require 'ipsw_ext'
require 'pp'

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

class RestoreService < DeviceService

  def output_progress(operation, progress)
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

  def query_debug_info
    obj = {
        "Request" => "QueryValue",
        "QueryKey" => "SavedDebugInfo",
    }
    write_plist(@socket, obj)
  end

  def send_start_restore_request

    #<key>Request</key><string>StartRestore</string>
    #<key>RestoreOptions</key>
    #<dict>
    #<key>AuthInstallRestoreBehavior</key><string>Erase</string>
    #<key>AutoBootDelay</key><integer>0</integer>
    #<key>BootImageFile</key><string>018-7919-343.dmg</string>
    #<key>CreateFilesystemPartitions</key><true/>
    #<key>DFUFileType</key><string>RELEASE</string>
    #<key>DataImage</key><false/>
    #<key>DeviceTreeFile</key><string>DeviceTree.n88ap.img3</string>
    #<key>FirmwareDirectory</key><string>Firmware</string>
    #<key>FlashNOR</key><true/>
    #<key>KernelCacheFile</key><string>kernelcache.release.n88</string>
    #<key>NORImagePath</key><string>all_flash.n88ap.production</string>
    #<key>PersonalizedRestoreBundlePath</key><string></string>
    #<key>RestoreBootArgs</key>
    #<string>rd=md0 nand-enable-reformat=1 -progress</string>
    #<key>RestoreBundlePath</key><string></string>
    #<key>RootToInstall</key><false/>
    #<key>SourceRestoreBundlePath</key><string></string>
    #<key>SystemImage</key><true/>
    #<key>SystemPartitionPadding</key>
    #<dict>
    #<key>16</key><integer>160</integer>
    #<key>32</key><integer>320</integer>
    #<key>8</key><integer>80</integer>
    #</dict>
    #<key>UUID</key><string>E6B885AE-227D-4D46-93BF-685F701313C5</string>
    #<key>UpdateBaseband</key><true/>
    #<key>UserLocale</key><string>zh_CN</string></dict>..
    #<key>RestoreProtocolVersion</key><integer>12</integer>

    obj = {
        "Request" => "StartRestore",
        "RestoreProtocolVersion" => 12,
        "RestoreOptions" => {
            "AuthInstallRestoreBehavior" => "Erase",
            "AutoBootDelay" => 0,
            "CreateFilesystemPartitions" => true,
            "DataImage" => false,
            "FlashNOR" => true,
            "RestoreBootArgs"=>"rd=md0 nand-enable-reformat=1 -progress",
            "RootToInstall" => false,
            "SystemImage" => true,
            "SystemPartitionPadding" => {
                "16" => 160,
                "32" => 320,
                "8" => 80,
            },
            "UUID" => "E6B885AE-227D-4D46-93BF-685F701313C5",
            "UpdateBaseband" => true,
        },
    }
    write_plist(@socket, obj)
  end

  def send_nor_data(ipsw_info)
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
    write_plist(@socket, response)
  end

  def send_kernel_cache(ipsw_info)
    puts "Got request for KernelCache data"

    kernel_data = File.open(ipsw_info[:file_kernelcache]).read
    kernel_data.blob = true
    response = {"KernelCacheFile" => kernel_data}
    write_plist(@socket, response)
  end

  def send_root_ticket(ipsw_info)
    puts "Got request for RootTicket data"

    root_ticket_data = File.open(ipsw_info[:file_ap_ticket]).read
    root_ticket_data.blob = true
    response = {"RootTicketData" => root_ticket_data}
    write_plist(@socket, response)
  end

  def start_asr(ipsw_info)
    puts "Got request for system image data"
    asr = ASRService.new(PORT_ASR)
    asr.start(ipsw_info)
  end

  def start_restore(ipsw_info)
    p "query_debug_info"
    query_debug_info()

    p "starting restore"
    send_start_restore_request()

    p "loop..."
    loop do
      plist = read_plist(@socket)
      p "got plist", plist

      if plist["MsgType"] =="DataRequestMsg"
        puts "DataRequestMsg"

        data_type = plist["DataType"]
        if data_type == "SystemImageData"
          start_asr(ipsw_info)
        elsif data_type == "NORData"
          send_nor_data(ipsw_info)
        elsif data_type == "KernelCache"
          send_kernel_cache(ipsw_info)
        elsif data_type == "RootTicket"
          send_root_ticket(ipsw_info)
        end
      elsif plist["MsgType"] == "ProgressMsg"
        output_progress(plist["Operation"], plist["Progress"])
      elsif plist["MsgType"] == "StatusMsg"
        puts "Got status message: #{plist.inspect}"
        # break if plist["Status"] == 0
        break
      end
    end
  end

end

class ASRService < DeviceService

  def send_payload_info(crc_chunk_size, payload_size)
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
        "Checksum Chunk Size" => crc_chunk_size,
        "FEC Slice Stride" => 40,
        "Packet Payload Size" => 1450,
        "Packets Per FEC" => 25,
        "Payload" => {
            "Port" => 1,
            "Size" => payload_size,
        },
        "Stream ID" => 1,
        "Version" => 1
    }

    write_plist(obj)
  end

  def send_payload(f, crc_chunk_size)
    puts "Sending payload"
    f.seek(0)
    sent_len = 0
    total_len = f.stat.size
    while data = f.read(packet_len) do 
	  if true then
		sha1 = OpenSSL::Digest::Digest.new("SHA1").digest(data)
		buffer = data + sha1
	  else
		buffer = data
	  end
      @socket.write(buffer)
      sent_len += data.size
      puts "#{sent_len}/#{total_len}"
    end
    puts "Sending payload done."
  end

  def start(ipsw_info)

    p "start ASR."
    f = File.open(ipsw_info[:file_restoredmg])
    payload_size = f.stat.size
	crc_chunk_size = 0x20000

    send_payload_info(crc_chunk_size, payload_size)

    while plist = read_plist do
      if plist["Command"] == "OOBData"
        oob_length = plist["OOB Length"]
        oob_offset = plist["OOB Offset"]
        puts "Sending #{oob_length} OOB bytes from offset #{oob_offset}"
        f.seek(oob_offset)
        @socket.write(f.read(oob_length))
      elsif plist["Command"] == "Payload"
        send_payload(f, crc_chunk_size)
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

def do_restore ipsw_info
  restore = RestoreService.new(PORT_RESTORE)
  restore.start_restore(ipsw_info)

  p "reboot..."
end


if __FILE__ == $0
  ipsw_info = get_ipsw_info("n88ap", "ios5_0")
  #ipsw_info = get_ipsw_info("m68ap", "ios3_1_3")
  do_restore ipsw_info
end
