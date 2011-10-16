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

if __FILE__ == $0
  #test_tss_response()
  test_update_apticket()
end