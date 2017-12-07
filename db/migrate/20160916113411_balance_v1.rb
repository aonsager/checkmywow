class BalanceV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Balance Druid', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage Done</li><li>Cast Efficiency</li><li>DoT Uptime (Moonfire, Sunfire, Stellar Flare)</li></ul><p>Resources tab:</p><ul><li>Time not Astral Power-Capped</li><li>Astral Power Gained</li><li>Lunar Empowerment / Solar Empowerment Usage</li><li>Fury of Elune Effectiveness</li></ul><p>Cooldowns tab</p><ul><li>Starfall Effectiveness</li><li>Force of Nature Damage</li><li>Incarnation: Chosen of Elune Effectiveness</li><li>Celestial Alignment Effectiveness</li><li>Fury of Elune Damage</li></ul>');
  end
end
