class AddLogs < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string   :report_id, null: false
      t.string   :title
      t.integer  :zone
      t.datetime :started_at
      t.datetime :ended_at
      t.boolean  :imported, default: false
      t.timestamps
    end

    add_index :reports, :report_id, :unique => true
  end
end
