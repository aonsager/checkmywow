class FightParseV4 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 4).update_attributes(content: '<p>Stopped recording Spirit Eruptions and legendary ring explosions as part of damage-increasing abilities. Damage is recorded while the preceding buffs are active, so counting the explosion was resulting in double-dipping.</p><p>When a buff is refreshed, will now correctly treat it as two separate instances of the buff instead of simply extending duration.</p>');
  end
end
