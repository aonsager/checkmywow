class HavocV6 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 5).update_attributes(content: '<p>Stopped tracking Fel Barrage casts, since the number of charges is untrackable, and the total number of casts possible was inaccurate.</p><p>Fixed a bug that was showing the wrong amount of Fury when Demon\'s Bite was cast.</p>');
  end
end
