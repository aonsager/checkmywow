class Windwalker7V2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 2).update_attributes(content: '<ul><li>Flying Serpent Kick is now correctly tracked for mastery.</li><li>Cooldown reduction from haste is now considered when calculating the maximum casts possible of Rising Sun Kick and Fists of Fury</li><li>Chi gain/waste has been added to the resources tab</li></ul>');
  end
end
