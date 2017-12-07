class FightParseV5 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 5).update_attributes(content: '<p>Fixed an issue that prevented buffs from being properly recorded if they were activated before the fight began.</p>');
  end
end
