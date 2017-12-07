class AddSpecsToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :specs, :text, array: true, default: []

    FightParse.where(status: FightParse.statuses[:done]).each do |fp|
      player = fp.player
      unless player.specs.include? fp.spec
        player.specs << fp.spec 
        player.save
      end
    end
  end
end
