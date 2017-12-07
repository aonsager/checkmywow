class AddBossNameToFps < ActiveRecord::Migration
  def change
    add_column :fight_parses, :boss_name, :string
    add_column :fight_parses, :boss_percent, :integer
    FightParse.all.each do |fp|
      fp.boss_name = Boss.find(fp.boss_id).name rescue 'Unknown Boss'
      fp.boss_percent = Fight.find_by(report_id: fp.report_id, fight_id: fp.fight_id).boss_percent
      fp.save
    end
  end
end
