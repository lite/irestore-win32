#!/usr/bin/env ruby 
# encoding: utf-8

#$: << File.join(File.dirname(__FILE__), "./CFPropertyList/lib")

require 'rubygems'
require 'cfpropertylist'
# require 'plist'
# require 'Plist' # need ruby 1.9.2, not works on UTF8
# require 'nokogiri-plist' # not works on cygwin
# require 'plist4r'  # not works on cygwin

module PropertyList
  
  ## cfpropertylist
  def self.load(str)
    plist = CFPropertyList::List.new(:data => str)
    CFPropertyList.native_types(plist.value)
  end
  
  def self.dump(obj, fmt = nil)
    plist = CFPropertyList::List.new
    plist.value = CFPropertyList.guess(obj)
    plist.to_str(fmt == :xml1 ? CFPropertyList::List::FORMAT_XML : CFPropertyList::List::FORMAT_BINARY)
  end
end
