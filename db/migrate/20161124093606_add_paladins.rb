class AddPaladins < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Holy Paladin', version: 1).update_attributes(content: '<p>Healing Done</p><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Healing Efficiency per Mana spent</li><li>Infusion of Light Proc Usage</li><li>Always Be Casting</li></ul><p>Cooldown Usage</p><ul><li>Avenging Wrath Effectiveness</li><li>Holy Avenger Effectiveness</li><li>Lay on Hands Effectiveness</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Retribution Paladin', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Damage Done</li><li>Templar\'s Verdict Usage</li><li>Judgment Uptime</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Holy Power Gained</li><li>Holy Power Usage</li></ul>');
  end
end
