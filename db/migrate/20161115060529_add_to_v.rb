class AddToV < ActiveRecord::Migration
  def change
    Zone.create(id: 12, name: "Trial of Valor", enabled: true)
  end
end
