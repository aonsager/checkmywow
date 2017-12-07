class FightParse::Rogue::Subtlety < FightParse
  include Filterable
  self.table_name = :fp_rogue_sub

  def in_progress?
    return true
  end
end