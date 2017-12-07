class HavocV7 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 7).update_attributes(content: '<p>Added tracking to check that each Eye Beam tick hit more than one target.</p><p>Fixed some issues in the Cast Efficiency section</p>');
  end
end
