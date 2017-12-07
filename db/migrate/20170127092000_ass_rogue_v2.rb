class AssRogueV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Assassination Rogue', version: 2).update_attributes(content: '<p>Cooldown Usage</p><ul><li>Nightstalker/Subterfuge usage<ul><li>Cast the buffed bleed with full Combo Points</li><li>Let the buffed bleed tick for its full duration</li></ul></li></ul>');
  end
end
