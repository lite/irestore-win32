#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)
                  
require 'rubygems'
require 'pp'	
require 'base64'
require 'net/https'
require 'uri'
require 'img3file'
require 'fileutils' 
require 'pathname'
require 'plist_ext'
require 'ipsw_ext'

def update_img3file(ecid)
  ### unzip
  system("mkdir -p #{PATH_DMG}")
  system("unzip -d #{PATH_DMG} #{FILE_IPSW}")  

  ### tss request 
  # gc-apple-dump_03
  # tssrqst_fn = "./amai/debug/tss-request.plist"
  # payload = File.open(tssrqst_fn).read
  buffer = File.open(FILE_MANIFEST_PLIST).read
  # p buffer
  obj = PropertyList.load(buffer)
  # pp obj["BuildIdentities"][0]

  # pp obj
  rqst_obj = {
  	"@APTicket" => true, "@BBTicket" => true,  "@HostIpAddress" =>  "172.16.191.1",
  	"@HostPlatformInfo" => "mac", "@UUID" => "6D27AA8B-FE93-442D-B957-46BCC347D5FC",  
  	"@VersionInfo" =>  "libauthinstall-68.1",
    "ApECID" =>  ecid, # 86872710412, # "UniqueChipID"=>86872710412, get from ideviceinfo.rb
  	"ApProductionMode" => true
  }

  tmp = obj["BuildIdentities"][0] 
  manifest_info = {}

  tmp.each do |k, v|
  	case k
  	when "ApBoardID", "ApChipID", "ApSecurityDomain"
  		rqst_obj[k] = v
  	when "UniqueBuildID"
  		v.blob = true
  		rqst_obj[k] = v  
  	when "Manifest"
  		hash = {} 
  		tmp["Manifest"].each do |mk, mv|
  			#pp mk, mv   
  			unless mk =~ /Info/ 
  				hash[mk] ={}
  		 	 	mv.each do |vk, vv|
   					#pp vk, vv
  	        case vk
  					when "Info"
  					  manifest_info = manifest_info.merge({mk => vv["Path"]})
  					when "PartialDigest", "Digest"
  						vv.blob = true
  						hash[mk] = hash[mk].merge({vk => vv})
  					else
    					hash[mk] = hash[mk].merge({vk => vv}) 
  					end
  				end     
  			end
  		end
  		rqst_obj = rqst_obj.merge(hash)
  	end
  end        

  #pp manifest_info   

  # pp rqst_obj
  payload = PropertyList.dump(rqst_obj, :xml1)
  # p payload 

  # http post 
  uri_gs_serv = "http://gs.apple.com/TSS/controller?action=2"
  #uri_gs_serv = "http://cydia.saurik.com/TSS/controller?action=2"
  #uri_gs_serv = "http://127.0.0.1:8080/TSS/controller?action=2" 
  uri = URI.parse(uri_gs_serv)
  http = Net::HTTP.new(uri.host, uri.port)       
  request = Net::HTTP::Post.new(uri.request_uri)
  request["User-Agent"] = "InetURL/1.0" 
  request["Content-Length"] = payload.length
  request["Content-Type"] = 'text/xml; charset="utf-8"'  
  request.body = payload                    
  response = http.request(request)
  
  if response.body.include?("STATUS=0&MESSAGE=")
    # STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING=
    buffer = response.body.split("&REQUEST_STRING=")[1]
    # tssresp_fn = "./amai/debug/tss-response.plist"
    # buffer = File.open(tssresp_fn).read
    obj = PropertyList.load(buffer)
  
    if not obj.nil? 
      ### patch img3
      manifest_info.each do |k, v|
        p k
        if obj.include?(k)
          #pp k, v 
          filename = File.join(PATH_DMG, v)    
          img3 = Img3File.new
          data = File.open(filename,'r').read
          img3.parse(StringIO.new(data)) 

          ### change the img3 file
          blob = obj[k]["Blob"]
          img3.update_elements(StringIO.new(blob), blob.length)
		  
          tmp_filename = File.join(PATH_DMG_NEW, v) 
          FileUtils.mkdir_p(Pathname.new(tmp_filename).dirname)    
          f = File.open(tmp_filename, "wb")
          f.write(img3.to_s) 
          f.close        
        end
      end
    end
  else
    # STATUS=94&MESSAGE=This device isn't eligible for the requested build.
    p response.body
  end  
    
end 

if __FILE__ == $0
  update_img3file(86872710412)
end

