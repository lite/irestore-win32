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
  info=getdeviceinfo
  enter_recovery
  ecid = info["UniqueChipID"] #86872710412
  model=info["HardwareModel"] #"M68AP"
  p ecid, model
  ipsw_ver = "ios5_0"
  ipsw_info = get_ipsw_info(model, ipsw_ver)
  update_img3file(ecid, ipsw_info) if model != "M68AP"
  enter_restore
  do_restore 
  do_activate(true)
end