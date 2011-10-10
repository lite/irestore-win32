#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'ipsw_ext'
require 'pp'

def test_get_iphone3gs_ios5
  pp get_ipsw_info("n88ap", "ios5_0")
end

def test_get_iphone3gs_ios4
  pp get_ipsw_info("n88ap", "ios4_3_5")
end

def test_get_iphone2g_ios3
  pp get_ipsw_info("m68ap", "ios3_1_3")
end

if __FILE__ == $0
  test_get_iphone3gs_ios5
  #test_get_iphone3gs_ios4
  #test_get_iphone2g_ios3
end