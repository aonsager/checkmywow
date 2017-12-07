class AddTalentsToFp < ActiveRecord::Migration
  def change
    add_column :fight_parses, :talents, :string
    add_column :fight_parses, :fight_length, :integer
  end
end
