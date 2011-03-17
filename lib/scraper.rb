# encoding: UTF-8
require 'open-uri'
require 'nokogiri'


class Scraper

  CENTER_TYPES = {
    :hospital => '5_1'
  }

  PROVINCES = %w(Almer%EDa C%E1diz C%F3rdoba Granada Huelva Ja%E9n M%E1laga Sevilla)

  URL = 'http://www.juntadeandalucia.es/servicioandaluzdesalud/centros'

  class << self

    def go!
      hospitals = extract_hospitals
      store_in_cartodb hospitals
    end

    def extract_hospitals
      puts 'Hospitals scraper'
      puts '======================================='
      center_type = CENTER_TYPES[:hospital]
      hospital_links = []
      hospitals = []

      if Rails.env.test?
        provinces = PROVINCES.first(1)
      end
      puts ''
      puts 'Getting list of hospitals...'

      (provinces || PROVINCES).each do |province|
        uri = "#{URL}/Resultados.asp?CodTipoCentro=#{center_type}&Provincia=#{province}"
        doc = Nokogiri::HTML(open(uri))
        hospital_links += doc.css('div#canvas_form form table.centros tr td div.barra2_1 span.titulo a').map{|a| {:name => a.text, :link => a[:href]}}
      end
      puts '... done!'
      hospitals_found = "= #{hospital_links.count} hospitals found ="
      puts Array.new(hospitals_found.length, '=').join
      puts hospitals_found
      puts Array.new(hospitals_found.length, '=').join

      if Rails.env.test?
        hospital_links = hospital_links.first(1)
      end

      puts ''
      puts 'Scrapping hospitals:'
      hospital_links.each_with_index do |hospital_link, index|
        puts ''
        puts "Scraping #{hospital_link[:name]} (#{index + 1}/#{hospital_links.count})..."
        uri = "#{URL}/#{hospital_link[:link]}"

        doc = Nokogiri::HTML(open(URI.escape(uri)))
        name             = doc.css('div#canvas h2').text
        address          = doc.css('form#formulario div.block280 div.barra2_1:nth-child(3) span.dato').text.strip
        city             = doc.css('form#formulario div.block280 div.barra2_1:nth-child(4) span.dato').text.strip
        region           = doc.css('form#formulario div.block280 div.barra2_1:nth-child(5) span.dato').text.strip
        postal_code      = doc.css('form#formulario div.block280 div.barra2_1:nth-child(6) span.dato').text.strip
        complete_address = "#{address}, #{city}, #{region}, #{postal_code}"

        emergency_contact = doc.css('form#formulario div.block245 span.datoenlinea strong').text

        hospital_website  = nil
        hospital_website_link = doc.css('form#formulario div.block245 span.datoenlinea a')
        if hospital_website_link.present?
          hospital_website = hospital_website_link.first[:href]
          hospital_website  = $1 if hospital_website && hospital_website[/(http.*)/]
        end

        # Extracts latitude and longitude from the javascript code
        javascript = doc.css('html head script').text
        latlong_regexp = /var cX = (-?\d+\.\d+);var cY = (-?\d+\.\d+);/
        latitude, longitude = *[javascript[latlong_regexp, 1], javascript[latlong_regexp, 2]]
        latitude, longitude = *georeference_place(complete_address) if latitude.blank? && latitude.blank?

        puts '... done!'

        hospitals << {
          :name              => name,
          :address           => complete_address,
          :emergency_contact => emergency_contact,
          :website           => hospital_website,
          :latitude          => latitude.to_f,
          :longitude         => longitude.to_f
        }
      end

      hospitals
    end
    private :extract_hospitals

    def store_in_cartodb(rows)
      puts ''
      puts 'Storing scraped data into CartoDB.com...'
      near_hospitals_table = create_schema
      return unless near_hospitals_table.present? && rows.present?

      rows.each do |row|
        CartoDB::Connection.insert_row near_hospitals_table.name, row
      end
      puts '... done!'
    end
    private :store_in_cartodb

    def create_schema
      near_hospitals_table = nil
      begin
        CartoDB::Connection.drop_table "near_hospitals_#{Rails.env}"
      rescue CartoDB::CartoError => e
      end

      near_hospitals_table = CartoDB::Connection.create_table "near_hospitals_#{Rails.env}", [
                                                                {:name => 'address',           :type => 'string'},
                                                                {:name => 'emergency_contact', :type => 'string'},
                                                                {:name => 'website',           :type => 'string'}
                                                              ]
      near_hospitals_table
    end
    private :create_schema

    def georeference_place(address)
      puts '****************************'
      puts "Georeferencing #{address}..."
      require 'net/http'
      # Georeference that address, getting a latitude and a longitude
      url = URI.parse("http://maps.google.com/maps/api/geocode/json?address=#{CGI.escape(address)}&sensor=false")
      req = Net::HTTP::Get.new(url.request_uri)
      res = Net::HTTP.start(url.host, url.port){ |http| http.request(req) }
      json_googlemaps = JSON.parse(res.body)
      lat = nil
      lon = nil
      begin
        lon = json_googlemaps['results'][0]['geometry']['location']['lng']
        lat = json_googlemaps['results'][0]['geometry']['location']['lat']
      rescue
      end
      puts '... done!'
      puts '****************************'
      [lat, lon]
    end
    private :georeference_place

  end

end