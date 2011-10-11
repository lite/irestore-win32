VBox on osx/linux
====

start vbox

    run "sh run_vbox.sh" 
    after 30 seconds, use vrdp connect to 127.0.0.1:3389

Prepare
====

download the ipsw from internet

    http://www.littleyu.com/article/soft_apple.html
    http://appldnld.apple.com/iPhone4/041-1921.20110715.ItuLh/iPhone2,1_4.3.4_8K2_Restore.ipsw
    
Setup
====

osx
----

install libusb

    brew install libusb
    brew install socat
    socat -x -v tcp-l:27015,reuseaddr,fork unix:/var/run/usbmuxd &
    -v     verbose data traffic, text
    -x     verbose data traffic, hexadecimal

cygwin
----

user

    mkpasswd -l > /etc/passwd
    mkgroup -l > /etc/group

sshd 
   
    ssh-host-config -y  # tty ntsec
    ssh-user-config
    cygrunsrv -S sshd

cygwin

    http://www.cygwin.com/

packages

    make automake cmake gcc gdb patch
    unzip curl ruby git wget subversion cvs coreutils binutils openssh
    libxml2-devel openssl-devel zlib-devel ncurses bison 

SSL certs

    mkdir -p /usr/ssl/certs
    cd /usr/ssl/certs
    curl http://curl.haxx.se/ca/cacert.pem | awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "cert" n ".pem"}'
    c_rehash

library
----
	
rubygems

    http://rubygems.org/pages/download
    ruby setup.rb install

install rvm and gems

    bash < <(curl -k https://rvm.beginrescueend.com/install/rvm)
    source ~/.bashrc
    rvm install 1.9.2
    gem install rake
    gem install bundler
    gem install libxml-ruby
    gem install bit-struct
    gem install CFPropertyList

FAQ
----
	
	  install gcc on cygwin
	  
    extconf failure: need libm

Run
----

put iphone ipsw under the path: ~/tools/iOS/ 
  
    chmod +x s-irecovery.exe
    ruby main.rb
    
and run

Ref
----

irecovery
	
    http://github.com/iH8sn0w/syringe-irecovery
    
ribusb
    
    http://github.com/libin/ribusb

CFPropertyList

    http://github.com/ckruse/CFPropertyList

iTools    

    http://itools.hk/cms/?p=282

win32_sms

    https://raw.github.com/gist/85729/135a0181467d2785a1d51a5a7551b7486f96c068/win32_sms.rb

DeviceIOView

    nirsoft

win32
----
C:\Documents and Settings\Administrator\Application Data\Apple Computer\iTunes\iPhone Software Updates

C:\Documents and Settings\Administrator\Local Settings\Application Data\Apple\Apple Software Update
C:\Documents and Settings\All Users\Application Data\Apple Computer\iTunes\iPhone Temporary Files
