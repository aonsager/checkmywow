class ShadowPriestV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Shadow Priest', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Premonition Uptime</li><li>Mental Fatigue Uptime</li></ul><p>Auspicious Spirits</p><ul><li>Shadow Word: Pain Uptime</li><li>Vampiric Touch Uptime</li></ul><p>Clarity of Power</p><ul><li>Mind Blast Casts</li><li>DoT Weaving Effectiveness</li></ul><p>Resources tab:</p><ul><li>Shadow Orb Generation</li><li>Devouring Plague Casts</li></ul><p>Cooldowns tab</p><ul><li>Nithramus Damage</li><li>Insanity Damage</li><li>Cascade / Divine Star / Halo Damage</li><li>Shadow Word: Death Damage</li></ul>');
  end
end
