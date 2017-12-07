class BrewmasterV5 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 4).update_attributes(patch: '< 7.2')
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 5).update_attributes(patch: '7.2.5', content: '<p>Updated base purify percent to 50% to 40%, and accounts for Staggering Around traits.</p><p>Accounts for Quick Sip\'s purify effect.</p>');
  end
end
