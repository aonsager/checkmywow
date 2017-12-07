class UpdateShadow725 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Shadow Priest', version: 2).update_attributes(patch: '7.2.5');
  end
end
