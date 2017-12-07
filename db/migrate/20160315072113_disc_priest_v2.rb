class DiscPriestV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Discipline Priest', version: 2).update_attributes(content: '<p>Resources tab:</p><ul><li>Borrowed Time Uptime</li><li>Penance Casts</li><li>Power Word: Solace Casts</li></ul><p>Cooldowns tab:</p><ul><li>Archangel Effectiveness</li><li>Pain Suppression Effectiveness</li><li>Power Word: Barrier Effectiveness</li><li>Halo Effectiveness</li></ul>');
  end
end
