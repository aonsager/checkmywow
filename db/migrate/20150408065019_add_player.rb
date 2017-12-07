class AddPlayer < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.integer  :player_id, null: false
      t.string   :player_name
      t.string   :class_type
      t.text
      t.timestamps
    end

    add_index :players, :player_id, :unique => true
  end
end
