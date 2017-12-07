class RestoDruidV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Restoration Druid', version: 2).update_attributes(patch: '7.2.5', content: '<p>Added tracking for healing gained by Essence of G\'Hanir</p><p>Updated to 7.2.5</p>');
  end
end
