class FightParseV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 2).update_attributes(content: '<p>Fixed an issue that showed damage done as 0 while Spirit Shift was active.</p><p>This damage still will not be counted for overall DPS calculation, but will correctly attribute damage increases to other cooldowns');
  end
end
