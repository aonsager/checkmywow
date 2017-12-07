class MistweaverV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Mistweaver Monk', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Healing Done</li><li>Cast Efficiency</li><li>Renewing Mist Uptime</li><li>Enveloping Mist Effectiveness</li></ul><p>Resources tab:</p><ul><li>Healing Efficiency per Mana spent</li><li>Uplifting Trance Proc Usage</li><li>Thunder Focus Tea Usage</li><li>Mana Tea Usage</li><li>Lifecycles Usage</li><li>Teachings of the Monastery: Blackout Kick Usage</li></ul><p>Cooldowns tab</p><ul><li>Life Cocoon Effectiveness</li><li>Revival Effectiveness</li><li>Essence Font Effectiveness</li><li>Refreshing Jade Wind Effectiveness</li><li>Chi-Ji Effectiveness</li></ul>');
  end
end
