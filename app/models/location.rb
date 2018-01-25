class Location < ApplicationRecord
  belongs_to :route, inverse_of: :locations
  validates_presence_of :latitude, :longitude, :location_type
end
