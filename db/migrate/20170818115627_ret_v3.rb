class RetV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Retribution Paladin', version: 3).update_attributes(patch: '7.2.5', content: '<p>Updated to 7.2.5</p>');
  end
end
