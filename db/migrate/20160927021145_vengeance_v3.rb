class VengeanceV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Vengeance Demonhunter', version: 2).update_attributes(content: '<p>Added support for the artifact weapon, and various talents.</p><p>Key Metrics:</p><ul><li>Tracking casts of various talents.</li></ul><p>Cooldowns:</p><ul><li>Fel Devastation damage</li></ul>');
    Changelog.find_or_create_by(fp_type: 'Vengeance Demonhunter', version: 3).update_attributes(content: 'September 23 Hotfix: Demon Spikes damage reduction increased to 20%.');
  end
end
