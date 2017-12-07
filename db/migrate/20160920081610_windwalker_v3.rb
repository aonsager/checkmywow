class WindwalkerV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 3).update_attributes(content: '<p>Gale Burst damage is displayed for each cast of Touch of Death.');
  end
end
