#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'update_img3file'

def test_tss_response
  tssrqst_filename = "/home/dli/tools/iOS/ipsw/dmg_bak/tss-request.plist"
  payload = File.open(tssrqst_filename).read
  response = get_tss_response(payload)
  pp response.body
  buffer = response.body.split("&REQUEST_STRING=")[1]
  obj = PropertyList.load(buffer)
  tssresp_filename = "/home/dli/tools/iOS/ipsw/dmg_bak/tss-request.plist"
  update_apticket(tssresp_filename, obj)
end

if __FILE__ == $0
  test_tss_response()
end