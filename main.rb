#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'update_img3file'
require 'irecoverymode'
require 'iactivate'

p RUBY_PLATFORM

if /darwin/ =~ RUBY_PLATFORM
  # require 'osx_irestoremode'
#   require 'osx_irestore'
# else
  require 'irestoremode'
  require 'irestore'
end

if __FILE__ == $0
  enter_recovery
  update_img3file
  enter_restore
  do_restore 
  do_activate(true)
end