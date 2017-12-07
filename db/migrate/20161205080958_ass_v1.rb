class AssV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Assassination Rogue', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Rupture Uptime</li><li>Garrote Uptime</li><li>Lethal Poison Uptime</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Time not Energy-Capped</li><li>Combo Points Gained</li><li>Combo Points Usage</li><ul><li>Rupture</li><li>Envenom</li</ul></ul>');
  end
end
