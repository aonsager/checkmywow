class BrewmasterV4 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 4).update_attributes(content: '<p>Added tracking of Brew-stache uptime</p>');
  end
end
