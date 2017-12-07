class AddOrderToZones < ActiveRecord::Migration
  def change
    add_column :zones, :order_id, :integer

    Zone.find(13).order_id = 1
    Zone.find(16).order_id = 2
  end
end
