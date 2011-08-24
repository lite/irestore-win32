#!/usr/bin/env ruby 
# encoding: utf-8

require 'rubygems'
require 'cfpropertylist'
# require 'plist'
# require 'Plist' # need ruby 1.9.2, not works on UTF8
# require 'nokogiri-plist' # not works on cygwin
# require 'plist4r'  # not works on cygwin
require 'pp'

module PropertyList
  
  ## cfpropertylist
  def self.load(str)
    plist = CFPropertyList::List.new(:data => str)
    CFPropertyList.native_types(plist.value)
  end
  
  def self.dump(obj, fmt = nil)
    begin
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(obj)
      plist.to_str(fmt == :xml1 ? CFPropertyList::List::FORMAT_XML : CFPropertyList::List::FORMAT_BINARY)
    rescue
      pp obj, fmt, "~~~~~~~~~~"
    end
  end
end

def test_xml_to_plist
   buffer = File.open("example.xml").read
   obj = PropertyList.load(buffer)
   puts PropertyList.dump(obj)
end

def test_plist_to_xml
   buffer = File.open("example.plist").read
   obj = PropertyList.load(buffer)
   puts PropertyList.dump(obj, :xml1)
end

def test_cfpropertylist
	# create a arbitrary data structure of basic data types
	data = {
	  'name' => 'John Doe',
	  'missing' => true,
	  'last_seen' => Time.now,
	  'friends' => ['Jane Doe','Julian Doe'],
	  'likes' => {
		'me' => false
	  }
	}

	# create CFPropertyList::List object
	plist = CFPropertyList::List.new

	# call CFPropertyList.guess() to create corresponding CFType values
	plist.value = CFPropertyList.guess(data)
	# write plist to file
	plist.save("example.plist", CFPropertyList::List::FORMAT_BINARY)
  plist.save("example.xml", CFPropertyList::List::FORMAT_XML)

	# … later, read it again
	plist = CFPropertyList::List.new(:file => "example.plist")
	data = CFPropertyList.native_types(plist.value)
end

def test_array
	data = ['Jane Doe','Julian Doe'];
	plist = CFPropertyList::List.new
	plist.value = CFPropertyList.guess(data)
	pp plist.value
	data = CFPropertyList.native_types(plist.value)
	pp data
end

def test_hash
	data = {:item => 'Jane Doe', :value=>'Julian Doe'};
	plist = CFPropertyList::List.new
	plist.value = CFPropertyList.guess(data)
	pp plist.value
	data = CFPropertyList.native_types(plist.value)
	pp data
end

if __FILE__ == $0
  # test_array
  # test_hash
  # test_cfpropertylist
  test_plist_to_xml
  # test_xml_to_plist
end