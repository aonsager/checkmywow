class MarksmanshipV5 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Marksmanship Hunter', version: 5).update_attributes(content: '<p>Tracks when the last cast of Aimed Shot occured for each application of Vulnerable, if Patient Sniper is chosen as a talent.</p><p>Tracks your DPS while you have 30 stacks of Bullseye.</p>');
  end
end
