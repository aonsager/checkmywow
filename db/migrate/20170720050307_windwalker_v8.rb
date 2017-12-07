class WindwalkerV8 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 7).update_attributes(patch: '< 7.2')
    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 8).update_attributes(patch: '7.2.5', content: '<p>Changed max Hit Combo stacks from 8 to 6.</p><p>Calculates Fists of Fury cooldown reduction from T20 2-piece set bonus.');
  end
end
