class FireV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Fire Mage', version: 2).update_attributes(content: '<p>Tracks Phoenix\'s Flames damage.</p>');
  end
end
