#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.dirname(__FILE__)

require 'rubygems'
require 'net/https'
require 'uri'
require 'img3file'
require 'fileutils'
require 'pathname'
require 'plist_ext'
require 'ipsw_ext'
require 'rexml/document'
require 'irecoveryinfo'

def hex_string_to_binary(hex_string)
  hex_string.scan(/.{2}/).map{ |x| x.hex.chr }.join
end

def get_tss_payload(dev_info, ipsw_info)
  buffer = File.open(ipsw_info[:file_manifest_plist]).read
  # p buffer
  obj = PropertyList.load(buffer)
  # pp obj["BuildIdentities"][0]

  #<key>@APTicket</key><true/>
  #<key>@BBTicket</key><true/>
  #<key>@HostIpAddress</key><string>192.168.1.101</string>
  #<key>@HostPlatformInfo</key><string>windows</string>
  #<key>@UUID</key><string>38E214DF-F33E-BA44-908C-39257A02784A</string>
  #<key>@VersionInfo</key><string>libauthinstall-107.3</string>
  #<key>ApBoardID</key><integer>0</integer>
  #<key>ApChipID</key><integer>35104</integer>
  #<key>ApECID</key><integer>86872710412</integer>
  #<key>ApNonce</key><data>mZLyYI2NFgck+ZEbycwpiazVsi8=</data>
  #<key>ApProductionMode</key><true/>
  #<key>ApSecurityDomain</key><integer>1</integer>

  #{"CPID"=>"8920", "CPRV"=>"15", "CPFM"=>"03", "SCEP"=>"04", "BDID"=>"00",
  #"ECID"=>"000000143A045D0C", "IBFL"=>"03", "SRNM"=>"[889437758M8]",
  #"NONC"=>"7A2C0D05B3C9908A9F27100E04862E237FE0DA78"}

  #ecid = dev_info["UniqueChipID"] #86872710412
  #ap_chip_id = 35104 #info[]
  #ap_nonce = "Y0rxrVEzJpYJhADmqCto+o1oCk0=".unpack('m0')[0]
  ap_nonce = hex_string_to_binary(dev_info["NONC"])
  ap_nonce.blob=true

  ecid = dev_info["ECID"].to_i(16)
  ap_chip_id = dev_info["CPID"].to_i(16)
  ap_board_id = dev_info["BDID"].to_i(16)
  rqst_obj = {
      "@APTicket" => true,
      "@BBTicket" => true,
      "@HostIpAddress" => "192.168.1.101",
      "@HostPlatformInfo" => "windows",
      "@UUID" => "E6B885AE-227D-4D46-93BF-685F701313C5",
      "@VersionInfo" => "libauthinstall-107.3",
      "ApBoardID" => ap_board_id,
      "ApChipID" => ap_chip_id,
      "ApECID" => ecid, # 86872710412, # "UniqueChipID"=>86872710412, get from ideviceinfo.rb
      "ApNonce" => ap_nonce, # must set on iOS5
      "ApProductionMode" => true,
      "ApSecurityDomain" => 1,
  }

  tmp = obj["BuildIdentities"][0]
  manifest_info = {}

  tmp.each do |k, v|
    case k
      when "UniqueBuildID"
        v.blob = true
        rqst_obj[k] = v
      when "Manifest"
        hash = {}
        tmp["Manifest"].each do |mk, mv|
          #pp mk, mv
          unless mk =~ /Info|OS/
            hash[mk] ={}
            mv.each do |vk, vv|
              #pp vk, vv
              case vk
                #when "Info"
                #  manifest_info = manifest_info.merge({mk => vv["Path"]})
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

  payload = PropertyList.dump(rqst_obj, :xml1)
  return manifest_info, payload
end

def get_tss_response(payload)
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
  http.request(request)
end

def patch_img3_files(manifest_info, obj)
  manifest_info.each do |k, v|
    p k
    if obj.include?(k)
      #pp k, v
      filename = File.join(PATH_DMG, v)
      img3 = Img3File.new
      data = File.open(filename, 'r').read
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

def update_apticket(apticket_filename, obj)
  # ap_nonce
  # 01 D5 23 60 13 D0 7E 34 31 96 4A 00 FE 4F 3F C0 7A 88 A2 6C

  # 0x017 - 0x2e ap_ecid
  # 0C 5D 04 3A 14 00 00 00

  # 0x114 - 0x128
  # 01 D5 23 60 13 D0 7E 34 31 96 4A 00 FE 4F 3F C0 7A 88 A2 6C

  # 0x21e - 0x232
  # FB AF E9 19 3A 93 5E 84 37 26 EA 19 75 97 2B CD AB 9D 9B 37

  # 0x2ef - 0x36f
  # 11 21 87 71 2A AB 5C BC 63 26 DC 9A 6C CA 89 71
  # 70 81 5A C5 8D BF 55 A1 8C 03 3C 40 A8 8B A4 7B
  # 60 65 30 BE 61 47 02 7C EB 36 72 F2 3C 8E EC 13
  # 8C 27 04 DF 7D 8B 1C CF 24 FC CF 69 0D F7 7A 3D
  # E0 83 72 E1 3E 1A 56 DB 0A 46 11 3D FA 67 ED A9
  # E5 17 35 96 5A 9E 01 82 01 DF 73 54 37 77 72 52
  # CF D5 FF 4F 3D 3A 02 A5 FC 8C 37 B2 56 85 1A 3B
  # CA 33 66 7D 73 27 B8 A8 69 01 24 84 6C CF 0A 87

  puts "APTicket", apticket_filename
  data = obj["APTicket"]
  f = File.open(apticket_filename, "wb+")
  f.write(data)
  f.close
end

def update_img3file(dev_info, ipsw_info)
  manifest_info, payload = get_tss_payload(dev_info, ipsw_info)
  response = get_tss_response(payload)

  if response.body.include?("STATUS=0&MESSAGE=")
    buffer = response.body.split("&REQUEST_STRING=")[1]
    obj = PropertyList.load(buffer)

    if not obj.nil?
      patch_img3_files(manifest_info, obj)
      update_apticket(ipsw_info[:file_ap_ticket], obj)
    end
  else
    # STATUS=94&MESSAGE=This device isn't eligible for the requested build.
    p response.body
  end

end

if __FILE__ == $0
  ipsw_info = get_ipsw_info("n88ap", "ios5_0")
  unzip_ipsw ipsw_info
  dev_info = get_irecovery_info()
  #update_img3file(4302652613389, ipsw_info) #4302652613389
  update_img3file(dev_info, ipsw_info)
end

