require 'pp'
require 'json'
require 'csv'
require 'net/http'
require 'uri'
require 'rest-client'
require 'open-uri'
require 'cgi'

namespace :biopin do

  WIKI_API="https://no.wikipedia.org/w/api.php?"
  WIKI_PAGES="https://no.wikipedia.org/wiki/"
  # def picture(url_str)
  #   url = URI.parse(url_str)
  #   req = Net::HTTP.new(url.host, url.port)
  #   res = req.request_head(url.path)
  #   picture_url = nil
  #   puts res.code
  #   if res.code == "200"
  #     res = Net::HTTP.get_response(url)
  #     doc = Nokogiri::HTML(res.body)
  #     nodes = doc.xpath("//img")
  #     picture_url = nodes.first["src"][2..-1]
  #   end
  #   return picture_url
  # end
  #
  # def fetch(uri_str, limit = 10)
  #   # You should choose better exception.
  #   raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  #
  #   url = URI.parse(uri_str)
  #   req = Net::HTTP::Get.new(url.path, { 'User-Agent' => ua })
  #   response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
  #   case response
  #   when Net::HTTPSuccess     then response
  #   when Net::HTTPRedirection then fetch(response['location'], limit - 1)
  #   else
  #     response.error!
  #   end
  # end

  def get_page_info(s)
    # henter pageimage
    params = "action=query&prop=pageimages&piprop=name&format=json"
    url = "#{WIKI_API}#{params}&titles=#{s.navn}&redirects"
    
    puts "will get page from URL: %s"  %url
    uri = URI.escape url
    response = RestClient.get uri
    if response.code == 200
      #puts response.body
      jsonObject = JSON.parse(response.body)
      #pp jsonObject
      pages = jsonObject["query"]["pages"].keys.first
      s.update_attributes({wikipageid: pages})
      if pages != "-1"
        pageinfo = jsonObject["query"]["pages"][pages]
        #pp pageinfo
        attributes = {url: WIKI_PAGES + pageinfo["title"], pageid:pages, 
                    title:pageinfo["title"], pageimage:pageinfo["pageimage"],
                    was_redirected: jsonObject["query"]["redirects"].present?} 
        #pp attributes
        if s.wikipedia_page.present?
          s.wikipedia_page.update_attributes(attributes)
        else
          s.wikipedia_page = WikipediaPage.new(attributes)
        end
      end
      pp s.wikipedia_page
    end     
  end  
  
  def get_item(hash, item, attribute)
    hash[item].present? ? hash[item][attribute] : nil
  end
  
  def get_image_metadata(s)
    # henter metadata
     uri = "https://no.wikipedia.org/w/api.php?action=query&prop=imageinfo&iiprop=extmetadata&titles=Fil:%s&format=json" % CGI::escape(s.wikipedia_page.pageimage)
    
    response = RestClient.get uri
    if response.code == 200
      jsonObject = JSON.parse(response.body)
      imageinfo = jsonObject["query"]["pages"]["-1"]["imageinfo"]
      if imageinfo.present?
        metadata = imageinfo.first["extmetadata"]
        attributes = {description: get_item(metadata, "ImageDescription", "value"),
                      filename: s.wikipedia_page.pageimage,
                      credit: get_item(metadata, "Credit", "Value"),
                      artist: get_item(metadata, "Artist", "value"),
                      license_short_name: get_item(metadata, "icenseShortName", "value"),
                      license_url: get_item(metadata, "LicenseUrl", "value"),
                      attribution_required: get_item(metadata, "AttributionRequired", "value"),
                      usage_terms: get_item(metadata, "UsageTerms", "value"),
                      copyrighted: get_item(metadata, "Copyrighted", "value"),
                      license: get_item(metadata, "License", "value")
                    }
      
        #puts "\tgot metadata for filename: %s" % s.wikipedia_page.pageimage
        if s.wikipedia_image.present?
          s.wikipedia_image.update_attributes(attributes)
        else
          s.wikipedia_image = WikipediaImage.new(attributes)
        end         
      else
        puts "\tdid not find metadata for filename: %s" % s.wikipedia_page.pageimage     
      end    
    end       
  end


  def get_image_url(s)
   uri = "https://no.wikipedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url&titles=Fil:%s&continue&iiurlwidth=100&format=json" % CGI::escape(s.wikipedia_page.pageimage)
   response = RestClient.get uri
#   response = RestClient.get uri)
   if response.code == 200
     #puts response.body
     jsonObject = JSON.parse(response.body)
     imageinfo = jsonObject["query"]["pages"]["-1"]["imageinfo"]
     if imageinfo.present?

       thumburl = imageinfo.first["thumburl"]
       # metadata = jsonObject["query"]["pages"]["-1"]["imageinfo"].first["extmetadata"]
       # pp metadata  
       attributes = {description_url: imageinfo.first["descriptionurl"],
                   thumb_url: imageinfo.first["thumburl"],
                   url: imageinfo.first["url"]
                   }
       puts "\tgot image url: %s" % attributes[:url]              
                 
       s.wikipedia_image.update_attributes(attributes)
     else
       puts "fant ikke bilde for: "
       puts uri
       puts URI.escape(uri)
       puts URI::encode(uri)
       puts CGI::escape(uri)
       pp jsonObject
       exit -1
     end
   end 
  end

  def sanitize(value)
    (value.nil? or value.is_a? String) ? value : value.round
  end


  def get_wikipedia_info(s)
    # først finne ut om det finnes en side for denne arten
    # sjekker https://no.wikipedia.org/wiki/<artsnavn>
    
    get_page_info(s)
    if s.wikipedia_page.present? 
      if s.wikipedia_page.pageimage.present?     
        get_image_metadata(s)
        get_image_url(s)
      else
        puts "\tspecies has wiki page, but without picture"
      end
    else
      puts "\tspecies does not have wiki page"
    end

    

    # wikipage_url = URI.escape("https://no.wikipedia.org/wiki/%s" % s.navn)
   #  #puts response.code
   #  print ": sjekker %s" % wikipage_url
   #  begin
   #    response = RestClient.get wikipage_url
   #    if response.code == 200
   #      # s.wiki_url= url_str
   #      # s.save
   #      puts " -> OK"
   #      puts response.body
   #      get_page_info(s,wikipage_url)
   #      if s.wikipedia_page.pageimage.present?
   #        #get_image_metadata(s)
   #        #get_image_url(s) if s.wikipedia_image.present?
   #      else
   #        puts "\tpage does not have picture"
   #      end
   #      #page = WikipediaPage.new()
   #    else
   #      puts " -> response.code %i, fant ikke siden" % response.code
   #    end
   #      s.wikipedia_response_code = response.code
   #      s.save
   #  rescue RestClient::ResourceNotFound => e
   #    puts " -> response.code %i, fant ikke siden" % e.response.code
   #    s.wikipedia_response_code = e.response.code
   #    s.save
   #  end
    
  end
  
  # for testing: 
  # desc %{get wikipedia info for "krassere"}
  # task :get_wikipedia_krassere => :environment do |t, args|
  #   s = Species.find_by_navn('krassere')
  #   puts s.navn
  #   # går bare videre dersom arten har norsk navn
  #   if s.navn.present? and !s.navn.blank?
  #     get_wikipedia_info(s)
  #   end
  # end  

  desc %{get wikipedia info for all species, that does not have already}
  task :get_wikipedia_info_all => :environment do |t, args|
   # species =  Species.includes(:wikipedia_page).
    #            where("wikipedia_pages.species_id IS NULL AND wikipedia_response_code IS NULL").references(:wikipedia_page)
    species =  Species.where("not exists (select * from wikipedia_pages where species_id = species.id) and wikipageid is null and navn is not null").order(:takson_id)
    i = 1
    for s in species do
      # går bare videre dersom arten har norsk navn
      if s.navn.present? and !s.navn.blank?
        print "%i: %s -> " % [i, s.navn]  
        get_wikipedia_info(s)
        i += 1
        #break if i > 1000
      end
    end    
    puts "Antall behandlet: %i" % i
  end  

  desc %{get wikipedia info for one species, named by an argument}
  task :get_wikipedia_info_one,[:navn] => :environment do |t, args|

    species =  Species.where('navn = ?', args[:navn])
    if species.present?
      puts species.first.navn
      s = species.first
      get_wikipedia_info(s)
    end    
  end 
  
  # desc %{check if wiki-page exists}
  # task :add_wiki_url => :environment do |t, args|
  #
  #   species = Species.where("wiki_url IS  NULL and wiki_url_return_code is null")
  #   for s in species do
  #     if s.navn.present? and !s.navn.blank?
  #       url_str = URI.escape("https://no.wikipedia.org/wiki/" + s.navn.capitalize)
  #       url = URI.parse(url_str)
  #       req = Net::HTTP.new(url.host, url.port)
  #       res = req.request_head(url.path)
  #       s.wiki_url_return_code = res.code
  #       if res.code == "200"
  #         s.wiki_url= url_str
  #         puts "saved " + url_str
  #       else
  #         puts "skip " + url_str
  #       end
  #       s.save
  #     end
  #   end
  # end 
  
  desc %{import data from CSV}
  task :import, [:filename] => :environment do |t, args|

    puts args[:filename]

    counter = 0
    file = File.new(args[:filename], "r")
    #while (line = file.gets) and counter < 3 do
    while (line = file.gets)
        #puts "#{counter}: #{line}"
        if counter > 0
          tmp = line.split("\t")
          array = []
          tmp.each do | str|
            tmp = (str[0] == "\"" ? str[1..-2] : str)
              array << (tmp.size == 0 ? nil : tmp)
          end
          
          hovedstatus = array[30]
          bistatus = array[31]
          #puts "hovedstatus:"
          #puts hovedstatus
          #puts array[0]
          if (hovedstatus == "Synonym" && bistatus == "Illegitimt")
             puts "ikke gyldig, hopper over..."
             next
           end
            
          #pp array
          attributes = {latinsk_navn_id: array[0], 
                        rike: array[1], 
                        underrike: array[2],
                        rekke: array[3],
                        underrekke: array[4],
                        overklasse: array[5],
                        klasse: array[6],
                        underklasse: array[7],
                        infraklasse: array[8],
                        kohort: array[9],
                        overorden: array[10],
                        orden: array[11],
                        underorden: array[12],
                        infraorden: array[13],
                        overfamilie: array[14],
                        familie: array[15],
                        underfamilie: array[16],
                        tribus: array[17],
                        undertribus: array[18],
                        slekt: array[19],
                        underslekt: array[20],
                        seksjon: array[21],
                        art: array[22],
                        underart: array[23],
                        varietet: array[24],
                        form: array[25],
                        overordna_latinsk_navn_id: array[26],
                        hovedstatus: array[30],
                        bistatus: array[31],
                        kommentar: array[37],
                        takson_id: array[38],
                        gyldig_latinsk_navn_id: array[39],
                        finnes_i_norge: array[40],
                        navn: array[41]
                      }
          s = Species.find_by takson_id: attributes[:takson_id].to_s
          if s.nil?
             s = Species.create(attributes)
          else
             s.update_attributes(attributes)
          end

        end
        puts counter
        counter = counter + 1
    end
    puts counter
    file.close

  end
  
  
end
