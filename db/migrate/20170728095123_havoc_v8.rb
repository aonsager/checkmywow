class HavocV8 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 7).update_attributes(patch: '< 7.2')
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 8).update_attributes(patch: '7.2.5', content: '<p>Changed Chaos Blades damage increase to 30%</p>');
  end
end
