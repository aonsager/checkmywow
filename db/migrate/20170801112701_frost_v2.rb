class FrostV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Frost Mage', version: 1).update_attributes(patch: '< 7.2')
    Changelog.find_or_create_by(fp_type: 'Frost Mage', version: 2).update_attributes(patch: '7.2.5', content: '<p>Basic</p><ul><li>Brain Freeze Proc Usage</li><li>Winter\'s Chill Proc Usage</li><li>Fingers of Frost Usage</li></ul><p>Cooldowns</p><ul><li>Icy Veins Damage</li><li>Rune of Power Damage</li><li>Mirror Image Damage</li><li>Frozen Orb Damage</li><li>Ray of Frost Damage</li></ul>');
  end
end
