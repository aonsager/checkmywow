class MarksmanshipHunterV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Marksmanship Hunter', version: 2).update_attributes(content: '<p>Basic tab:</p><ul><li>Chimaera Shot Efficiency</li><li>Aimed Shot casts with Careful Aim</li></ul><p>Resources tab:</p><ul><li>Time not Focus-Capped</li><li>Sniper Training Uptime</li><li>Steady Focus Uptime</li></ul><p>Cooldowns tab</p><ul><li>Maalus Effectiveness</li><li>Rapid Fire Damage</li><li>Glaive Toss Effectiveness</li><li>Barrage Effectiveness</li><li>Kill Shot Damage</li></ul>');
  end
end
