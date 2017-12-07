class RetributionV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Retribution Paladin', version: 2).update_attributes(content: '<p>Key Metrics</p><ul><li>Holy Power spent with Judgment active</li></ul><p>Cooldown Usage</p><ul><li>Crusade Damage</li><li>Holy Power Spent During Crusade</li><li>Avenging Wrath Damage</li></ul>');
  end
end
