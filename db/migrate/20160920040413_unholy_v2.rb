class UnholyV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Unholy Deathknight', version: 2).update_attributes(content: '<p>Tracks Apocalypse damage, along with the number of Festering Wound stacks consumed.</p>');
  end
end
