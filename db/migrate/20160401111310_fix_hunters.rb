class FixHunters < ActiveRecord::Migration
  def change
    FightParse.where(status: 3, spec: 'Marksmanship').each do |fp|
      next if fp.casts_hash.nil?
      fp.resources_hash[:as_casts] = fp.casts_hash['Aimed Shot'].to_i
      fp.save
    end
  end
end
