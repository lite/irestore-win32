#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'win32device'

def get_usb_description(value, index, length)
  dev = Win32Device.new
  dev.open
  desc = dev.get_usb_description(value, index, length)
  dev.close
  desc
end

def usb_scription_to_string(data)
  #length, type = data.unpack("CC")
  data[8+2..-1].unpack("S*").pack("C*")
end

def get_irecovery_description
  #21.0  CTL    80 06 04 03  09 04 ff 00                            GET DESCRIPTOR     51us       198.1.0(2)
  #21.0  IN     b6 03 43 00  50 00 49 00  44 00 3a 00  38 00 39 00  ..C.P.I.D.:.8.9.  437us       198.2.0
  #             32 00 30 00  20 00 43 00  50 00 52 00  56 00 3a 00  2.0. .C.P.R.V.:.              198.2.16
  #             31 00 35 00  20 00 43 00  50 00 46 00  4d 00 3a 00  1.5. .C.P.F.M.:.              198.2.32
  #             30 00 33 00  20 00 53 00  43 00 45 00  50 00 3a 00  0.3. .S.C.E.P.:.              198.2.48
  #             30 00 34 00  20 00 42 00  44 00 49 00  44 00 3a 00  0.4. .B.D.I.D.:.              198.2.64
  #             30 00 30 00  20 00 45 00  43 00 49 00  44 00 3a 00  0.0. .E.C.I.D.:.              198.2.80
  #             30 00 30 00  30 00 30 00  30 00 30 00  31 00 34 00  0.0.0.0.0.0.1.4.              198.2.96
  #             33 00 41 00  30 00 34 00  35 00 44 00  30 00 43 00  3.A.0.4.5.D.0.C.              198.2.112
  #             20 00 49 00  42 00 46 00  4c 00 3a 00  30 00 33 00   .I.B.F.L.:.0.3.              198.2.128
  #             20 00 53 00  52 00 4e 00  4d 00 3a 00  5b 00 38 00   .S.R.N.M.:.[.8.              198.2.144
  #             38 00 39 00  34 00 33 00  37 00 37 00  35 00 38 00  8.9.4.3.7.7.5.8.              198.2.160
  #             4d 00 38 00  5d 00                                  M.8.].                        198.2.176
  bytes = get_usb_description(0x0304, 0x0409, 0xFF)
  usb_scription_to_string(bytes)
end

def get_ap_nonce
  #21.0  CTL    80 06 01 03  09 04 00 01                            GET DESCRIPTOR     75us       204.1.0(2)
  #21.0  IN     5e 03 20 00  4e 00 4f 00  4e 00 43 00  3a 00 32 00  ^. .N.O.N.C.:.2.  423us       204.2.0
  #             34 00 46 00  31 00 45 00  31 00 46 00  38 00 34 00  4.F.1.E.1.F.8.4.              204.2.16
  #             46 00 30 00  31 00 34 00  31 00 45 00  33 00 32 00  F.0.1.4.1.E.3.2.              204.2.32
  #             39 00 36 00  43 00 34 00  44 00 41 00  31 00 35 00  9.6.C.4.D.A.1.5.              204.2.48
  #             35 00 35 00  33 00 36 00  31 00 34 00  43 00 32 00  5.5.3.6.1.4.C.2.              204.2.64
  #             38 00 32 00  41 00 39 00  43 00 30 00  46 00        8.2.A.9.C.0.F.                204.2.80
  bytes = get_usb_description(0x0301, 0x0409, 0x100)
  usb_scription_to_string(bytes)
end

def get_irecovery_info
  string = get_irecovery_description() + get_ap_nonce()
  items = {}
  string.split(" ").each do | item |
    key = item.split(":")[0]
    value = item.split(":")[1]
    items[key] = value
  end
  items
end

