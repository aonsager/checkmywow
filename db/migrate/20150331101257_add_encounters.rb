class AddEncounters < ActiveRecord::Migration
  def change
    create_table :zones do |t|
      t.string   :name
      t.timestamps
    end

    create_table :bosses do |t|
      t.string   :name
      t.integer  :zone_id
      t.integer  :order_num
      t.timestamps
    end
  end
end
