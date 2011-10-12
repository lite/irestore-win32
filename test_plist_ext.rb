#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'plist_ext'
require 'pp'

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
  # plist.save("example.plist", CFPropertyList::List::FORMAT_BINARY)
  #   plist.save("example.xml", CFPropertyList::List::FORMAT_XML)

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

def test_data
  require 'base64'
  filename = "/home/dli/tools/iOS/ipsw/dmg/ap-ticket.dat"
  f = File.open(filename)
  obj = {"RootTicketData"=>  f}
  puts PropertyList.dump(obj, :xml1)
end

if __FILE__ == $0
  # test_array
  # test_hash
  # test_cfpropertylist
  #test_plist_to_xml
  # test_xml_to_plist
  test_data
end