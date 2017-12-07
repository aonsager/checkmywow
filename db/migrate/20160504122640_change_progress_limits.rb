class ChangeProgressLimits < ActiveRecord::Migration
  def change
    change_column :progresses, :current, :integer, limit: 8, default: 0
    change_column :progresses, :finish, :integer, limit: 8, default: 1
  end
end
