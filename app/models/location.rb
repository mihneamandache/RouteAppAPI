class Location < ApplicationRecord
  belongs_to :route, inverse_of: :locations
  validates_presence_of :latitude, :longitude
  validates :location_type, inclusion: ["start", "goal", "intermmediate"]
end
