class CreateFails < ActiveRecord::Migration
  def change
    create_table :fails do |t|
      t.string   :model_type, null: false
      t.string  :model_id, null: false
      t.string   :status
      t.integer  :lock_version
      t.timestamps
    end

    add_index :fails, [:model_type, :model_id], :unique => true
  end
end
