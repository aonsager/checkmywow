class WindwalkerV4 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 4).update_attributes(content: '<p>Shows how many times your SEF clones hit with Fists of Fury. Because their channel time is unaffected by haste, you may clip their last hit if you cast your next spell too early');
  end
end
