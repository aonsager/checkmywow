class RenameExternalCooldown < ActiveRecord::Migration
  def change
    rename_table :external_buff_parses, :external_cooldown_parses
  end
end
