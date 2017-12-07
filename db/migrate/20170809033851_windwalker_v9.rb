class WindwalkerV9 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 9).update_attributes(patch: '7.2.5', content: '<p>Added tracking for Rising Sun Kick cooldown reduction from T19 2-piece bonus.</p><p>Added tracking for Pressure Point (T20 4-piece bonus) proc usage.</p>');

    Changelog.find_or_create_by(fp_type: 'Beastmastery Hunter', version: 1).update_attributes(patch: nil)
    Changelog.find_or_create_by(fp_type: 'Frost Mage', version: 1).update_attributes(patch: nil)
    Changelog.find_or_create_by(fp_type: 'Enhancement Shaman', version: 2).update_attributes(patch: nil)
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 7).update_attributes(patch: nil)
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 4).update_attributes(patch: nil)
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 7).update_attributes(patch: nil)

  end
end
