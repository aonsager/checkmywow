class WindwalkerV6 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 6).update_attributes(content: '<p>Added tracking for the total amount of cooldown reduction gained through Serenity.</p>');
  end
end
