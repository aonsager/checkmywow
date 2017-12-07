class ArmsV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Arms Warrior', version: 1).update_attributes(content: '<p>Basic</p><ul><li>Damage per second</li><li>Colossus Smash uptime</li><li>Shattered Defenses proc usage</li><li>Rend Uptime</li></ul><p>Cast Efficiency</p><p>Resources</p><ul><li>Rage gained</li><li>Rage usage during Execute range</li><li>Mortal Strike usage during Execute range</li></ul><p>Cooldowns<p><ul><li>Damage done while in Execute range</li><li>Battle Cry damage</li><li>Avatar damage</li><li>Bladestorm damage</li><li>Ravager damage</li></ul>', patch: '7.2.5');
  end
end
