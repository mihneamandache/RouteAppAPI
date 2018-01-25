class Route < ApplicationRecord
  has_many :locations
  accepts_nested_attributes_for :locations

  def make_api_call

    api_url = "https://api.openstreetmap.org/api/0.6/map?bbox="

    #RestClient.get(api_url + )
    locations.each do |location|
      puts location.latitude.to_i
      api_url += location.longitude.to_s + ',' + location.latitude.to_s + ','
    end

    api_url.chop!

    puts api_url
    RestClient.get(api_url)
  end
end
