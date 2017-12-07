class WindwalkerV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 2).update_attributes(content: '<p>Will correctly count the number of Tigereye Brew stacks consumed when the buff is refreshed before running out.</p>');
  end
end
