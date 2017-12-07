class ResourceType
  MANA = 0
  RAGE = 1
  FOCUS = 2
  ENERGY = 3
  COMBOPOINTS = 4
  RUNES = 5
  RUNICPOWER = 6
  SOULSHARDS = 7
  ASTRALPOWER = 8
  HOLYPOWER = 9
  ALTERNATE = 10
  MAELSTROM = 11
  CHI = 12
  INSANITY = 13
  ARCANECHARGES = 16
  FURY = 17
  PAIN = 18

  def self.resource_name(id)
    return {
      0 => 'Mana',
      1 => 'Rage',
      2 => 'Focus',
      3 => 'Energy',
      4 => 'Combo Points',
      5 => 'Runes',
      6 => 'Runic Power',
      7 => 'Soul Shards',
      8 => 'Astral Power',
      9 => 'Holy Power',
      10 => 'Alternate',
      11 => 'Maelstrom',
      12 => 'Chi',
      13 => 'Insanity',
      16 => 'Arcane Charges',
      17 => 'Fury',
      18 => 'Pain',
    }[id]
  end
end