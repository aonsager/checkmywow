class WindwalkerMonkV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 3).update_attributes(content: '<p>Will now correctly compare Maalus damage done across encounters when looking at logs by boss.</p>');
  end
end
