class ShadowPriestV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Shadow Priest', version: 3).update_attributes(content: '<p>DoT tracking no longer expects you to have DoTs active on all targets. A DoT will be considered active if it is active on at least one target.</p>');
  end
end
