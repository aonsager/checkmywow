class AssRogueV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Assassination Rogue', version: 3).update_attributes(content: '<p>Fixed Vendetta tracking</p><p>Added tracking for Surge of Toxins uptime</p><p>Fixed Nightstalker tracking to look for either Garotte or Rupture</p>');
  end
end
