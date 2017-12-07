class AddFights < ActiveRecord::Migration
  def change
    create_table :fights do |t|
      t.string   :report_id, null: false
      t.integer  :fight_id, null: false
      t.string   :name
      t.integer  :boss_id
      t.integer  :size
      t.integer  :difficulty
      t.boolean  :kill
      t.integer  :status, default: 0
      t.datetime :report_started_at
      t.integer  :started_at
      t.integer  :ended_at
      t.timestamps
    end

    add_index :fights, [:report_id, :fight_id], :unique => true
  end
end
