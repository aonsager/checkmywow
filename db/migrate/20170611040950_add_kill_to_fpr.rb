class AddKillToFpr < ActiveRecord::Migration
  def change
    add_column :fight_parse_records, :kill, :boolean, default: false
  end
end
