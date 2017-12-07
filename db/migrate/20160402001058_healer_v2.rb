class HealerV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Discipline Priest', version: 4).update_attributes(content: '<p>Fixed an issue that caused certain data to be missing from fights logged in a language other than English.</p><p>Fixed other minor bugs that were causing processing to fail for certain players</p>');
  end
end
