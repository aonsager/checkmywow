class Unholy7V1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Unholy Deathknight', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency</li><li>Festering Wound Efficiency</li><li>Virulent Plague Uptime</li><li>Soul Reaper Usage</li></ul><p>Resources tab:</p><ul><li>Time not Runic Power-Capped</li></ul><p>Cooldowns tab</p><ul><li>Dark Transformation Damage</li><li>Dark Arbiter Damage</li></ul>');
  end
end
