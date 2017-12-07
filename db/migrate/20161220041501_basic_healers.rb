class BasicHealers < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Outlaw Rogue', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Slice and Dice Uptime / Roll the Bones Uptime</li><li>Ghostly Strike Uptime</li><li>Opportunity Proc Usage</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Time not Energy-Capped</li><li>Combo Points Gained/Wasted</li><li>Combo Points Usage</li><ul><li>Slice and Dice</li><li>Roll the Bones</li><li>Run Through</li></ul></ul>');
    Changelog.find_or_create_by(fp_type: 'Destruction Warlock', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Eradication Uptime</li><li>Immolate Uptime</li><li>Havoc Uptime</li><li>Havoc Fails</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Soul Shards Gained/Wasted</li><li>Always Be Casting (Experimental)</li></ul>');

    Changelog.find_or_create_by(fp_type: 'Restoration Shaman', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Healing Done</li></ul><p>Resource Management</p><ul><li>Healing Efficiency per Mana spent</li><li>Always Be Casting (Experimental)</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Holy Priest', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Healing Done</li></ul><p>Resource Management</p><ul><li>Healing Efficiency per Mana spent</li><li>Always Be Casting (Experimental)</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Discipline Priest', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Healing Done</li></ul><p>Resource Management</p><ul><li>Healing Efficiency per Mana spent</li><li>Always Be Casting (Experimental)</li></ul>');
  end
end
