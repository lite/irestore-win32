#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.')

require 'cfpropertylist'

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

# … later, read it again
plist = CFPropertyList::List.new(:file => "example.plist")
data = CFPropertyList.native_types(plist.value)