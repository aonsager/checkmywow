class DiscPriestV3 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Discipline Priest', version: 3).update_attributes(content: '<p>Now counts only the initial cast of Penance, and not subsequent ticks<p>Fixed an issue that was showing incorrect numbers for healing increased by Archangel</p><p>Started tracking the increased shield amount caused by Archangel. Unused portions of this increased shield are shown as the expired shield amount</p><p>Started tracking what spell Empowered Archangel is used on</p>');
  end
end
