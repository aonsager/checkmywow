class BrewmasterV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 2).update_attributes(content: '<p>Added tracking for spells affected by Blackout Combo.</p>');
  end
end
