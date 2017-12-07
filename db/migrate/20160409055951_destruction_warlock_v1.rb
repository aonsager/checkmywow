class DestructionWarlockV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Destruction Warlock', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Immolate uptime</li><li>Flamelicked uptime</li></ul><p>Resources tab:</p><ul><li>Conflagrate casts</li><li>Time not Burning Embers-capped</li></ul><p>Cooldowns tab</p><ul><li>Shadowburn damage</li><li>Dark Soul damage</li><li>Havoc damage</li><li>Fire and Brimstone damage</li><li>Nithramus damage</li></ul>');
  end
end
