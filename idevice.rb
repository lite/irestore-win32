#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
$: << File.join(File.dirname(__FILE__), 'ribusb/lib')  

require 'rubygems'
require 'ribusb' 

class AppleDevice
  def initialize
    @USB = RibUSB::Bus.new
    @device = @USB.find(:idVendor => 0x5ac, :idProduct => 0x1281).first
  end
  
  def open
    set_configuration(1)
    set_interface_alt_setting(0, 0)
    self
  end

  def set_configuration(configuration)
    @device.configuration = configuration
  end
  
  def set_interface_alt_setting(interface, alt_setting)
    @device.claimInterface(interface)
    @device.setInterfaceAltSetting(interface, alt_setting)

    sleep(2)
  end
  
  def send_command(command)
    begin
      p "send_command #{command}.\n"
      @device.controlTransfer(:bmRequestType => 0x40, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataOut => command + "\0")
    rescue
      p "===="
    end
  end

  def recv_command
    begin
      receive_buffer = "\x00" * 0x10
      size = @device.controlTransfer(:bmRequestType => 0xC0, :bRequest => 0, :wValue => 0, :wIndex => 0, :dataIn => receive_buffer, :timeout => 0)
      p size
    
      receive_buffer[0, size]
    rescue
      p "----"
    end
  end
  
  def send_file(filename, is_recovery_mode=true)
    if is_recovery_mode then
      @device.controlTransfer(:bmRequestType => 0x41, :bRequest => 0, :wValue => 0, :wIndex => 0)
    else
      @device.controlTransfer(:bmRequestType => 0x21, :bRequest => 4, :wValue => 0, :wIndex => 0);
    end
    packet_size = 0
    total_size = File.size(filename)
    
    File.open(filename) do |f|
      while buffer = f.read(0x800) do
        if is_recovery_mode then
          @device.bulkTransfer(:endpoint=>4, :dataOut => buffer)
        else
          @device.controlTransfer(:bmRequestType => 0x21, :bRequest => 1, :wValue => 0, :wIndex => 0, :dataOut => buffer);
        end
                
        packet_size += buffer.size
        puts "#{packet_size}/#{total_size}"
      end
    end

    buffer = "\x00" * 6
  end
  
  def close
    begin
      @device.releaseInterface(0)
    rescue
      p "reboot..."
    end
      sleep(2)
  end
end
