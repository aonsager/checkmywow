class ProtPaladinV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Protection Paladin', version: 2).update_attributes(content: '<p>Tracks healing and damage done for the three lvl 90 talents.</p>');
  end
end
