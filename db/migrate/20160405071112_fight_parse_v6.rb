class FightParseV6 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 6).update_attributes(content: '<p>Fixed an issue with debuff/dot tracking that caused data to be incomplete. The uptime reports show now correctly show data for all enemies you attacked (an enemy will not show up if you never damaged it or applied a debuff to it).</p>');
  end
end
