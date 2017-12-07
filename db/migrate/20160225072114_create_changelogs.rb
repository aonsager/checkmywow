class CreateChangelogs < ActiveRecord::Migration
  def change
    create_table :changelogs do |t|
      t.string   :fp_type, null: false
      t.integer  :version, null: false
      t.text     :content
      t.timestamps
    end
    add_index :changelogs, [:fp_type, :version], :unique => true
  end
end
