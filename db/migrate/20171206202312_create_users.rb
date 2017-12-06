class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :last_name, null: false
      t.string :unique_identifier, null: false
    end
  end
end
