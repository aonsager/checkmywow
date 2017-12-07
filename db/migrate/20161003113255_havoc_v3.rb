class HavocV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Havoc Demonhunter', version: 3).update_attributes(content: '<p>Improved analysis of Momentum playstyle</p><ul><li>Percent of important abilities cast during Momentum<ul><li>Throw Glaive</li><li>Fury of the Illidari</li><li>Eye Beam</li><li>Fel Barrage</li></ul></li><li>Number of times Momentum was refreshed too early</li><li>Fury Management<ul><li>Fury gained during Momentum when not needed</li><li>Fury spent outside of Momentum when not needed</li></ul></li></ul><p>Added Fel Barrage tracking to the cooldowns tab</p>');
  end
end
