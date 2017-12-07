class BeastmasteryV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Beastmastery Hunter', version: 1).update_attributes(patch: '< 7.2')
    Changelog.find_or_create_by(fp_type: 'Beastmastery Hunter', version: 2).update_attributes(patch: '7.2.5', content: '<p>Reduced Bestial Wrath\'s cd reduction from Dire Beast to 12 seconds.</p><p>Kill Command has been removed from the Cast Efficiency table, as it is too difficult to determine a realistic target number of casts. Instead, a new section in the Resources tab shows how much damage per focus was done with each ability, so you can see if you are spending too much focus on low-damage abilities.</p>');
  end
end
