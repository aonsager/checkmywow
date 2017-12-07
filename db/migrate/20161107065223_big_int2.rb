class BigInt2 < ActiveRecord::Migration
  def change
    change_column :healing_parses, :started_at, :integer, limit: 8
    change_column :healing_parses, :ended_at, :integer, limit: 8
  end
end
