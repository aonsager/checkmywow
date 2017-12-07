class WindwalkerV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 1).update_attributes(content: '<p>First version of Fight Parses for patch 7.0</p>');

    Changelog.find_or_create_by(fp_type: 'Windwalker Monk', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency of key spells</li><li>Hit Combo uptime</li><li>Mastery Effectiveness</li></ul><p>Resources tab:</p><ul><li>Time not Energy-Capped</li></ul><p>Cooldowns tab</p><ul><li>Fists of Fury Effectiveness</li><li>Spinning Crane Kick Effectiveness</li><li>Touch of Death Effectiveness</li></ul>');
  end
end
