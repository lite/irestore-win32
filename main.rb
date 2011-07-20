#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ideviceinfo'
require 'update_img3file'
require 'irecoverymode'
require 'iactivate'
require 'irestore'

p RUBY_PLATFORM

if /darwin/ =~ RUBY_PLATFORM
  require 'osx_irestoremode'
else
  require 'cyg_irestoremode'
end

if __FILE__ == $0
  getdeviceinfo
  enter_recovery
  update_img3file
  enter_restore
  do_restore 
  do_activate(true)
end