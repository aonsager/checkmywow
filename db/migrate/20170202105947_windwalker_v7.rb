class WindwalkerV7 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Marksmanship Hunter', version: 5).update_attributes(content: '<p>Tracks damage dealt during Storm, Earth, and Fire.</p><p>Correctly shows clone damage separately during Fists of Fury.</p>');
  end
end
