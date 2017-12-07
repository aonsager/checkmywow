class Marksmanship7V1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Marksmanship Hunter', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency</li><li>Marking Tragets Proc Usage</li><li>Vulnerable Uptime</li><li>Damage Dealt While Vulnerable</li></ul><p>Resources tab:</p><ul><li>Time not Focus-Capped</li></ul><p>Cooldowns tab</p><ul><li>Trueshot Effectiveness</li></ul>');
  end
end
