class FightParseV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'FightParse', version: 3).update_attributes(content: '<p>Fixed an issue that prevented prepots from being recognized.</p><p>Tracks damage by DPS legendary ring explosion and records damage done while the buff was active, for all specs by default</p><p>Tracks Soul Capacitor explosion damage and records damage done while the buff was active, for all specs by default</p><p>Added some leeway to the number of possible casts of key abilities in a fight, since you often can\'t use them immediately after a pull</p>');
  end
end
