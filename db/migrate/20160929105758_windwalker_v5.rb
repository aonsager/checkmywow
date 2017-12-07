class WindwalkerV5 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 5).update_attributes(content: '<p>Tracks casts and damage done for Strike of the Windlord</p>');
  end
end
