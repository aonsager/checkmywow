class FightParse7V3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 3).update_attributes(content: '<p>Added more robust reporting for Cast Efficiency. You can now see when your spells came off cooldown, to see potential causes for delay.</p><p>Added death tracking. This shows damage and healing leading to your deaths, if any.</p>');
  end
end
