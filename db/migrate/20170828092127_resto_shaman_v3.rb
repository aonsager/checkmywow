class RestoShamanV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Restoration Shaman', version: 3).update_attributes(patch: '7.2.5', content: '<p>Updated for patch 7.2.5.</p>');
  end
end
