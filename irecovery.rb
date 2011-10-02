#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require "win32device"

class IRecovery

  def initialize

  end

  def send_command command
    puts "irecv_send_command", command
  end

  def send_file path
    puts "irecv_send_file", path
  end
end