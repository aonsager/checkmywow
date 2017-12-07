class FeralDruidV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Feral Druid', version: 2).update_attributes(content: '<p>Rip/Rake bleed tracking no longer expects you to have the bleed active on all targets. A bleed will be considered active if it is active on at least one target.</p>');
  end
end
