class ShadowV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Shadow Priest', version: 2).update_attributes(content: '<p>Tixed an issue with talent detection.</p><p>Started tracking healing done through Vampiric Embrace</p>');
  end
end
