class UnholyDeathknightV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Unholy Deathknight', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Dark Transformation uptime</li><li>Necrotic Plague uptime at 15 stacks</li><li>Blood Plague uptime</li><li>Frost Fever uptime</li><li>Soul Reaper usage</li></ul><p>Resources tab:</p><ul><li>Time not Runic Power-capped</li><li>Time not Blood Charge-capped</li><li>Runic Power pooled for each Breath of Sindragosa cast</li><li>Runic Power gained from Anti-Magic Shell</li></ul><p>Cooldowns tab</p><ul><li>Gargoyle damage</li><li>Breath of Sindragosa damage</li><li>Dark Transformation damage</li><li>Crazed Monstrosity damage</li><li>Thorasus damage</li></ul>');
  end
end
