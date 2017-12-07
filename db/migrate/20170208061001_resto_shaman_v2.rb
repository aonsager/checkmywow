class RestoShamanV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Restoration Shaman', version: 2).update_attributes(content: '<p>Key Metrics</p><ul><li>Chain Heal - Hitting more than 4 targets</li><li>Tidal Waves - Not wasting procs</li><li>Tidal Waves - Proc usage</li><li>Ancestral Vigor Uptime</li></ul><p>Cooldown Usage</p><ul><li>Spirit Link Totem Effectiveness (Experimental)</li><li>Healing Tide Totem Effectiveness</li><li>Ascendance Effectiveness</li><li>Ancestral Guidance Effectiveness</li><li>Gift of the Queen Effectiveness</li><li>Cloudburst Totem Effectiveness</li></ul>');
  end
end
