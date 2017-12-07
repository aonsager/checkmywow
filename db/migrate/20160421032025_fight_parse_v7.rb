class FightParseV7 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 7).update_attributes(content: '<p>Fixed an issue for classes with spells that have a significant travel time. Previously, if you refreshed a buff between when you cast a spell and when it hit your target, the spell damage would be attributed to the second instance of the buff. Now, it should correctly be attributed to the first instance, which was active when you cast the spell.</p>');
  end
end
