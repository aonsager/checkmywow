class RestoDruidV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Restoration Druid', version: 3).update_attributes(patch: '7.2.5', content: '<p>Added tracking for the total healing gained from Mastery: Harmony</p><p>Added tracking for Wild Growth healing.</p>');
  end
end
