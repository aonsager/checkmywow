class AddVoidScores < ActiveRecord::Migration
  def change
    add_column :fp_priest_shadow, :voidform_uptime, :integer
  end
end
