class HavocV2 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 2).update_attributes(content: '<p>Added support for the artifact weapon, and various talents.</p><p>Key Metrics:</p><ul><li>Tracking casts of Fel Rush and various talents.</li><li>Momentum uptime</li><li>Fury spent while Momentum was active</li></ul><p>Cooldowns:</p><ul><li>Fury of the Illidari damage</li><li>Chaos Blades damage</li>');
  end
end
