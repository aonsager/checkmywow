class BalanceV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Balance Druid', version: 3).update_attributes(patch: '7.2.5', content: '<p>Fixed Astral Power waste values being wrong at times.</p><p>Improved tracking of Solar/Lunar empowerment buffs.</p>');
  end
end
