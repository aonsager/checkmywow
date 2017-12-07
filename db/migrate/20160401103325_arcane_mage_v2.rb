class ArcaneMageV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Arcane Mage', version: 2).update_attributes(content: '<p>Fixed an issue that prevented Prismatic Crystal damage from being recorded if it existed at the beginning of the fight</p><p>Fixed an issue that caused incorrect values for uptimes of 4-stack Arcane Charge during burn phases</p>');
  end
end
