class ProtPaladinV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Protection Paladin', version: 2).update_attributes(content: '<p>Fixed an incorrect spell ID for Sacred Shield, so correct uptimes should be displayed now.</p>');
  end
end
