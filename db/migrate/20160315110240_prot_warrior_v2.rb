class ProtWarriorV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Protection Warrior', version: 2).update_attributes(content: '<p>Fixed an issue with Demoralizing Shout casts not correctly showing how much damage was reduced.</p>');
  end
end
