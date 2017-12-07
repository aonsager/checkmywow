class CreateProgresses < ActiveRecord::Migration
  def change
    create_table :progresses do |t|
      t.string   :model_type, null: false
      t.integer  :model_id, null: false
      t.integer  :current, default: 0
      t.integer  :finish, default: 1
    end
    add_index :progresses, [:model_type, :model_id], :unique => true
  end
end
