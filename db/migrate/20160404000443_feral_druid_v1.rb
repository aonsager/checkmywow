class FeralDruidV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Feral Druid', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Savage Roar Uptime - # combo points used when cast manually</li><li>Rip uptime - Combo points used, and Ferocious Bite usage (combo points and extra energy spent)</li><li>Rake uptime - buffs active when applied</li></ul><p>Resources tab:</p><ul><li>Time not energy-capped</li><li>Combo Point Generation</li></ul><p>Cooldowns tab</p><ul><li>Soul Capacitor damage</li><li>Maalus damage</li><li>Tiger\'s Fury damage</li></ul>');
  end
end
