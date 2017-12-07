class AddVersionToFp < ActiveRecord::Migration
  def change
    add_column :fight_parses, :expansion, :float, default: 6.2
    Changelog.delete_all
  end
end
