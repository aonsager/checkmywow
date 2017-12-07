class AddActorIdToFightParse < ActiveRecord::Migration
  def change
    add_column :fight_parses, :actor_id, :integer
  end
end
