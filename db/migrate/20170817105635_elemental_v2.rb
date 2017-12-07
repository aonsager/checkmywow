class ElementalV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Elemental Shaman', version: 2).update_attributes(patch: '7.2.5', content: '<p>Fixed max Maelstrom value.</p><p>Updated to 7.2.5</p>');
  end
end
