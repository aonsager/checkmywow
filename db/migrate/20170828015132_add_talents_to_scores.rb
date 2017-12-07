class AddTalentsToScores < ActiveRecord::Migration
  def change
    add_column :scores, :talents, :string
  end
end
