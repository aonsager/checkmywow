class FireMageV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Fire Mage', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency of key spells</li><li>Heating Up conversions</li></ul><p>Cooldowns tab</p><ul><li>Combustion Effectiveness</li></ul>');
  end
end
