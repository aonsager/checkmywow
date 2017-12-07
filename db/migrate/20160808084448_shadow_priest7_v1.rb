class ShadowPriest7V1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Shadow Priest', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency</li><li>Shadow Word: Pain Uptime</li><li>Vampiric Touch Uptime</li><li>Void Ray Uptime</li></ul><p>Resources tab:</p><ul><li>Insanity Gained Outside of Voidform</li><li>Voidform Uptime and Insanity Gained</li></ul><p>Cooldowns tab</p><ul><li>Nithramus Effectiveness</li><li>Voidform Effectiveness</li><li>Shadow Word: Death Damage</li><li>Power Infusion Effectiveness</li></ul>');
  end
end
