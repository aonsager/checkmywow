class AddLockingToProgress < ActiveRecord::Migration
  def change
    add_column :progresses, :lock_version, :integer
  end
end
