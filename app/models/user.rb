class User < ApplicationRecord
  validates_presence_of :name, :last_name, :unique_identifier
  validates :name, length: { minimum: 2, maximum: 50 }
  validates :last_name, length: { minimum: 2, maximum: 50 }

end
