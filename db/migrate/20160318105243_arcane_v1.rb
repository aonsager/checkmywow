class ArcaneV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Arcane Mage', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Arcane Missiles usage</li><li>Arcane Barrage usage</li></ul><p>Resources tab:</p><ul><li>Mana management during Conserve Phases</li><li>Burn phase execution</li><li>Evocation effectiveness</li><li>Runic Power uptime</li></ul><p>Cooldowns tab</p><ul><li>Nithramus Effectiveness</li><li>Arcane Power Effectiveness</li><li>Prismatic Crystal Effectiveness</li><li>Barrage Effectiveness</li><li>Kill Shot Damage</li></ul>');
  end
end
