class FixChangelog < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Marksmanship Hunter', version: 5).update_attributes(content: '<p>Tracks when the last cast of Aimed Shot occured for each application of Vulnerable, if Patient Sniper is chosen as a talent.</p><p>Tracks your DPS while you have 30 stacks of Bullseye.</p>');
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 7).update_attributes(content: '<p>Tracks damage dealt during Storm, Earth, and Fire.</p><p>Correctly shows clone damage separately during Fists of Fury.</p>');
  end
end
