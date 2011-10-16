#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'iservice'
require 'plist_ext'

class InfoService < DeviceService
  
  def enter_recovery
    # obj = {"ProtocolVersion"=>"2", "Request" => "QueryType" }
    obj = {"Request" => "EnterRecovery" }
    write_plist(@socket, obj)
    p read_plist(@socket)
  end
  
end

def enter_recovery
  d = InfoService.new(PORT_RESTORE)
  d.enter_recovery 
end

if __FILE__ == $0
  enter_recovery
end
