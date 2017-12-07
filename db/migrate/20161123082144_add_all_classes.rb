class AddAllClasses < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Frost Deathknight', version: 1).update_attributes(content: '<p>Frost Fever Uptime</p><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Time not Rune-Capped</li><li>Time not Runic Power-Capped</li><li>Runic Power Gained</li>');
    Changelog.find_or_create_by(fp_type: 'Survival Hunter', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Fury of the Eagle Usage</li><li>Way of the Mok\'Nathal Uptime</li><li>Lacerate Uptime</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Time not Focus-Capped</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Arcane Mage', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Nether Tempest Usage</li><li>Nether Tempest Uptime</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Burn Phase = Deplete Mana</li><li>Burn Phase - Stay at full Arcane Charge stacks</li><li>Evocation - Mana gained</li><li>Always be Casting</li></ul><p>Cooldown Usage</p><ul><li>Arcane Power Damage</li><li>Rune of Power Damage</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Frost Mage', version: 1).update_attributes(content: '<p>Cast Efficiency</p><p>Always Be Casting</p>');
    Changelog.find_or_create_by(fp_type: 'Feral Druid', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Rake Uptime</li><li>Rip Uptime</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Time not Energy-Capped</li><li>Combo Points Gained</li><li>Combo Points Usage</li><ul><li>Rip</li><li>Ferocious Bite</li><li>Savage Roar</li</ul></ul>');
  end
end
