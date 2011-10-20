#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'ideviceinfo'
require 'update_img3file'
require 'irecoverymode'
require 'iactivate'
require 'irestore'
require 'irecoveryinfo'

p RUBY_PLATFORM

if /darwin/ =~ RUBY_PLATFORM
  require 'osx_irestoremode'
else
  require 'cyg_irestoremode'
end

if __FILE__ == $0
  dev_info=getdeviceinfo
  enter_recovery
  wait_for_reboot

  model=dev_info["HardwareModel"].downcase #"M68AP"
  p model
  ipsw_info = get_ipsw_info(model, IPSW_VERSION)
  unzip_ipsw ipsw_info

  dev_info = get_irecovery_info()
  update_img3file(dev_info, ipsw_info) unless model == "m68ap"
  enter_restore(ipsw_info)
  wait_for_reboot

  do_restore(ipsw_info)
  #do_activate(true)
end