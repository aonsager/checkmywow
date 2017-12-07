class EnhancementV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Enhancement Shaman', version: 2).update_attributes(patch: '< 7.2')
    Changelog.find_or_create_by(fp_type: 'Enhancement Shaman', version: 3).update_attributes(patch: '7.2.5', content: '<p>Updated Tempest, Boulderfist, and Rockbiter to their current versions.</p><p>Added uptime tracking for Fury of Air and Lightning Crash.</p><p>Added Lightning Bolt to the casts section if the talent Overcharge is taken.</p><p>Added tracking for Hot Hand procs if the talent is taken.</p>');
  end
end
