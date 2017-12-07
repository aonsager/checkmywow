class AddDemonHunters < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency</li></ul><p>Resources tab:</p><ul><li>Time not Fury-Capped</li><li>Fury Gained</li></ul><p>Cooldowns tab</p><ul><li>Metamorphosis Effectiveness</li><li>Eye Beam Effectiveness</li></ul>');

    Changelog.find_or_create_by(fp_type: 'Vengeance Demonhunter', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage per Second</li><li>Damage Taken per Second</li><li>Self Healing per Second</li><li>External Healing per Second</li><li>Cast Efficiency</li><li>Soul Cleave Efficiency</li></ul><p>Resources tab:</p><ul><li>Time not Pain-Capped</li><li>Pain Gained</li></ul><p>Cooldowns tab</p><ul><li>Demon Spikes Effectiveness</li><li>Empower Wards Effectiveness</li><li>Fiery Brand Effectiveness</li></ul>');
  end
end
