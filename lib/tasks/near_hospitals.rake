namespace :near_hospitals do
  desc "Scrapes www.juntadeandalucia.es and gets all hospital info"
  task :scrape! => :environment do
    require 'scraper'

    Scraper.go!
  end
end