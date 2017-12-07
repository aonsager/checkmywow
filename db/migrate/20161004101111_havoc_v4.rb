class HavocV4 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 4).update_attributes(content: '<p>Improved detection of Momentum being refreshed too early. Refreshing early can be ok if you are hitting multiple targets with Fel Rush, and this section will now show if that was the case.</p>');
  end
end
