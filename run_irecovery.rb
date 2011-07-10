require 'Open3'

path_exe = "./s-irecovery.exe";
args = "-c reboot"
cmd = [path_exe, args].join(" ")
p cmd
#Open3.popen3("nslookup stackoverflow.com") { |i,o,e,t| puts o.read }
Open3.popen3(cmd) { |i,o,e,t| puts o.read }