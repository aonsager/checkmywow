class AddTimestampsToProgress < ActiveRecord::Migration
  def change
    add_column :progresses, :created_at, :datetime
    add_column :progresses, :updated_at, :datetime
  end
end
