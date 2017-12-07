class OutlawV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Outlaw Rogue', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Slice and Dice Uptime / Roll the Bones Uptime</li><li>Ghostly Strike Uptime</li><li>Opportunity Proc Usage</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Time not Energy-Capped</li><li>Combo Points Gained/Wasted</li><li>Combo Points Usage</li><ul><li>Slice and Dice</li><li>Roll the Bones</li><li>Run Through</li></ul></ul>');
  end
end
