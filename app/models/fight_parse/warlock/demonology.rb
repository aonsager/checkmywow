class FightParse::Warlock::Demonology < FightParse
  include Filterable
  self.table_name = :fp_warlock_demon

  def in_progress?
    return true
  end
end