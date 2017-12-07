class HavocV5 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 5).update_attributes(content: '<p>Added tracking for Fury gained from Fel Mastery.</p>');
  end
end
