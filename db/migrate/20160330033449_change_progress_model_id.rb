class ChangeProgressModelId < ActiveRecord::Migration
  def change
    change_column :progresses, :model_id, :string
  end
end
