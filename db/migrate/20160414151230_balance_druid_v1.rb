class BalanceDruidV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Balance Druid', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Moonfire uptime</li><li>Sunfire uptime</li><li>Starsurge Damage</li></ul><p>Resources tab:</p><ul><li>Starsurge casts</li><li>Lunar Empowerment usage</li><li>Solar Empowerment usage</li></ul><p>Cooldowns tab</p><ul><li>Celestial Alignment damage</li><li>Incarnation: Chosen of Elune damage</li><li>Starfall damage</li><li>Nithramus damage</li></ul>');
  end
end
