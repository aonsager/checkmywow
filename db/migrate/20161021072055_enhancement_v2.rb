class EnhancementV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Enhancement Shaman', version: 2).update_attributes(content: '<p>Tracks times when you used Lava Lash too early (had less than 90 Maelstrom).');
  end
end
