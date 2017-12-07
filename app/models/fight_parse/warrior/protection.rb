class FightParse::Warrior::Protection < TankParse
  include Filterable
  self.table_name = :fp_warrior_prot

  def in_progress?
    return true
  end
end