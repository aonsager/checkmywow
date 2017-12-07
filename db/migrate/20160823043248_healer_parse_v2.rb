class HealerParseV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'HealerParse', version: 2).update_attributes(content: '<p>Added a view to see healing done to raid members after they drop below 30% HP, until they reach at least 50% HP again. This shows how effectively you healed raid members who were low on health, and may reveal times when a death was avoidable with more targeted healing</p>');
  end
end
