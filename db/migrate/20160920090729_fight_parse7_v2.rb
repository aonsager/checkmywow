class FightParse7V2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 2).update_attributes(content: '<p>Added tracking for Legion potions and trinket procs.</p>');
  end
end
