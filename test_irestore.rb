#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'openssl'
require 'pp'

def crc_sha1_hexdiget(data)
	digest = OpenSSL::Digest::Digest.new("SHA1")
	puts digest.update(data)
	#return "B65756F616988CFB171945E0302CBADD96C65C36"
end

def crc_sha1(data)
	OpenSSL::Digest::Digest.new("SHA1").digest(data)
end

def test_asr_checksum
	filename = "/home/dli/tools/iOS/ipsw/dmg/018-7873-736.dmg"
	data = open(filename).read(0x20000)
	pp crc_sha1(data)
end

if __FILE__ == $0
	test_asr_checksum
end