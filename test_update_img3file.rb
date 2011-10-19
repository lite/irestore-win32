#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'update_img3file'

def test_tss_response
  tssrqst_filename = "/home/dli/tools/iOS/ipsw/dmg_bak/tss-request.plist"
  payload = File.open(tssrqst_filename).read
  response = get_tss_response(payload)
  pp response.body.split("&REQUEST_STRING=")[1]
end

def test_update_apticket
  tssresp_filename = "/home/dli/tools/iOS/ipsw/dmg_bak/tss-response.plist"
  buffer = File.open(tssresp_filename).read
  obj = PropertyList.load(buffer)
  apticket_filename = "/home/dli/tools/iOS/ipsw/dmg/apticket.der"
  update_apticket(apticket_filename, obj)
end

def test_ap_nonce
	ap_nonce = "mZLyYI2NFgck+ZEbycwpiazVsi8=".unpack('m0')[0]
	pp ap_nonce

	# 4A 81 64 49 E2 9F 95 20 1C E3 52 7B 96 C1 91 08 7D 03 35 3C
	# F5 0D D0 F6 49 0F 39 E8 2A 0E B7 34 A8 86 E2 A0 99 E0 0D B5
end

if __FILE__ == $0
  #test_tss_response()
  #test_update_apticket()
  test_ap_nonce
end