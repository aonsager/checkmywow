class MistweaverV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Mistweaver Monk', version: 2).update_attributes(content: '<p>Tracks healing from Sheilun\'s Gift.</p>');
  end
end
