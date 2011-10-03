#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'win32device'

class IRecoveryDevice

  def initialize
    @device = Win32Device::Win32Device.new
  end

  def open
    @device.open
    self
  end

  def close
    @device.close
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

  def send_file(filename, is_recovery_mode=true)
    p "send_file #{filename}.\n"
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
          sent = @device.bulkTransfer(:endpoint=>4, :dataOut => buffer)
        else
          sent = @device.controlTransfer(:bmRequestType => 0x21, :bRequest => 1, :wValue => 0, :wIndex => 0, :dataOut => buffer);
        end

        packet_size += buffer.size
        print_progress_bar(packet_size*100/total_size)
      end
    end

    print_progress_bar(100)

    buffer = "\x00" * 6
  end
end
