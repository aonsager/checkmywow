class GuardianV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Guardian Druid', version: 2).update_attributes(content: '<p>Fixed an issue that prevented Tooth and Claw damage reduction from being recorded correctly.</p>');
  end
end
