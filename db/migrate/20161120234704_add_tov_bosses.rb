class AddTovBosses < ActiveRecord::Migration
  def change
    Boss.find_or_create_by(id: 1958).update_attributes(name: "Odyn", zone_id: 12, order_num: 1)
    Boss.find_or_create_by(id: 1962).update_attributes(name: "Guarm", zone_id: 12, order_num: 2)
    Boss.find_or_create_by(id: 2008).update_attributes(name: "Helya", zone_id: 12, order_num: 3)
  end
end
