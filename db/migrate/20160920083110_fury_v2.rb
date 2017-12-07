class FuryV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Fury Warrior', version: 2).update_attributes(content: '<p>Tracks Odyn\'s Fury damage.');
  end
end
