class BrewmasterV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 2).update_attributes(content: '<p>Added tracking for damage avoided through Exploding Keg\'s debuff.</p>');
  end
end
