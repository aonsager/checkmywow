class Migrate71 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Blood Deathknight', version: 2).update_attributes(content: '<p>Update for patch 7.1:</p><ul><li>Added tracking for Icebound Fortitude</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Marksmanship Hunter', version: 3).update_attributes(content: '<p>Update for patch 7.1:</p><ul><li>Vulnerable only stacks up to 2 times</li></ul>');
  end
end
