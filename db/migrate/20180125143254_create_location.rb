class CreateLocation < ActiveRecord::Migration[5.1]
  def change
    create_table :locations do |t|
      t.belongs_to :route

      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :location_type, null:false
    end
  end
end
