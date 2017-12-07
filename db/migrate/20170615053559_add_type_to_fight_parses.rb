class AddTypeToFightParses < ActiveRecord::Migration
  def change
    add_column :fight_parses, :type, :string
  end
end
