class DifficultyType

  def self.label(id)
    return {
      1 => 'LFR', 
      2 => 'Flex', 
      3 => 'Normal', 
      4 => 'Heroic', 
      5 => 'Mythic'
    }[id]
  end
end