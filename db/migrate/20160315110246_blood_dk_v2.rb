class BloodDkV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Blood Deathknight', version: 2).update_attributes(content: '<p>Fixed an issue with Defile casts not correctly showing how much damage was reduced.</p>');
  end
end
