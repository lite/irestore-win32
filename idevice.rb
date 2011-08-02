#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
$: << File.join(File.dirname(__FILE__), 'ribusb/lib')  

require 'rubygems'
require 'ribusb' 
require 'ribusb/compat'

class AppleDevice
  @@matches = {}
  
  def self.match(value)
    [value[:vendor_id]].flatten.each do |vendor_id|
      (@@matches ||= {})[vendor_id] ||= {}

      [value[:product_id]].flatten.each do |product_id|
        @@matches[vendor_id][product_id] = self
      end
    end
  end
  
  def self.[](vendor_id, product_id)
    @@matches[vendor_id][product_id]
  end
  
  def self.available_devices
    available_ids = {}
    @@matches.each_pair do |vendor_id, value|
      value.each_pair do |product_id, klass|
        available_ids[[vendor_id, product_id]] = klass
      end
    end
        
    USB.devices.map do |device|
      available_ids[[device.idVendor, device.idProduct]].new(device) if available_ids.has_key?([device.idVendor, device.idProduct])
    end.compact
  end
  
  def initialize(device)
    @device = device
  end
end

class RestoreMode < AppleDevice
  match :vendor_id => 0x5ac, :product_id => [0x1290, 0x1291, 0x1292, 0x1294,] # iPhone, iPod Touch, iPhone3G, iPhone3Gs
  
  attr_reader :service
  
  def initialize(device)
    super(device)
  end
  
  def open
    # service = RestoreService.new(62078)
    # @service = Service[service.request_plist("Request" => "QueryType")["Type"]].new(62078)

    service = RestoreService.new(PORT_RESTORE)
    @service = Service[service.request_plist("Request" => "QueryType")["Type"]].new(PORT_RESTORE)

  end
  
  def recv_buffer   
    # ret = irecv_control_transfer(client, 0xC0, 0, 0, 0, (unsigned char*) response, 255, 1000);
    size = @handle.usb_interrupt_read(0x81, @receive_buffer, 0)
    # size = @handle.usb_control_read(0xC0, 0, 0, 0, @receive_buffer, 1000);
    
    @receive_buffer[0, size]
  end
  
end

class RecoveryV2Mode < AppleDevice
  match :vendor_id => 0x5ac, :product_id => 0x1281
  
  def initialize(device)
    super(device)
  end
  
  def open
    @handle = @device.open
    @handle.set_configuration(1)
    @handle.set_altinterface(0, 0)
    @handle.set_altinterface(1, 1)
    @receive_buffer = "\x00" * 0x400
    sleep(2)
    
    self
  end
  
  def send_command(command)
    begin
      p "send_command #{command}.\n"
      @handle.usb_control_write(0x40, 0, 0, 0, command + "\0", 0)
    rescue
      p "===="
    end
  end

  def recv_command
    size = @handle.usb_control_read(0xC0, 0, 0, 0, @receive_buffer, 0)
    
    @receive_buffer[0, size]
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
    printf "] #{progress}"
      printf "\n"  if progress == 100;
  end
  
  def send_file(filename)
    @handle.usb_control_write(0x41, 0, 0, 0, "", 1000)
    
    packet_size = 0
    total_size = File.size(filename)
    
    File.open(filename) do |f|
      while buffer = f.read(0x800) do
        @handle.usb_bulk_write(0x4, buffer, 1000)
        packet_size += buffer.size

        print_progress_bar(packet_size*100/total_size)
      end
    end
    
    print_progress_bar(100)

    buffer = "\x00" * 6
  end
  
  def close
    @handle.release_interface(1)
    @handle.release_interface(0)
    @handle.usb_close
    sleep(2)
    # @handle.usb_reset()
    
  end
end
