class AddPatchToChangelogs < ActiveRecord::Migration
  def change
    add_column :changelogs, :patch, :string
  end
end
