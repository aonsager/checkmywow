class SubtletyRogueV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Subtlety Rogue', version: 2).update_attributes(content: '<p>Debuff tracking no longer expects you to have debuffs active on all targets. A debuff will be considered active if it is active on at least one target.</p><p>Added Find Weakness uptime to the reports.</p>');
  end
end
