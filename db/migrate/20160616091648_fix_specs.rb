class FixSpecs < ActiveRecord::Migration
  def up
    FightParse.all.each do |fp|
      player = fp.player
      unless player.specs.include? fp.spec
        player.specs << fp.spec 
        player.save
      end
    end
  end
end
