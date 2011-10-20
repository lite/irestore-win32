#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'irecoveryinfo'
require 'pp'

def test_get_description
  puts "get_irecovery_info"
  desc = get_irecovery_description()
  puts desc
end

def test_get_ap_nonce
  puts "get_ap_nonce"
  desc = get_ap_nonce
  puts desc
end

def test_get_irecovery_info
  desc = get_irecovery_info()
  puts desc
end

def test_description_to_string
  desc = "abc efg"
  bytes = desc.unpack("C*")
  data = "\0"*8 + [desc.size, 0x03].pack("CC") + bytes.pack("S*")
  string = usb_scription_to_string(data)
  puts string
end

if __FILE__ == $0
  test_get_irecovery_info
  #test_description_to_string
end