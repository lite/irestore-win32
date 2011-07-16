#!/usr/bin/env ruby 
# encoding: utf-8

require 'rubygems'
require 'Open3'

$path_exe = "./s-irecovery.exe";

def run_irecovery(args)
  cmd = [$path_exe, args].join(" ")
  Open3.popen3(cmd) { |i,o,e,t| puts o.read }
end

run_irecovery("-c reboot")