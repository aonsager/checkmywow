class Shadow7V2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Shadow Priest', version: 2).update_attributes(content: '<p>September 26 Hotfix: Void Ray maximum stacks reduced to 4</p>');
  end
end
