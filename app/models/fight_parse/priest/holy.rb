class FightParse::Priest::Holy < HealerParse
  include Filterable
  self.table_name = :fp_priest_holy

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      healing_done: 0,
      pet_healing_done: 0,
      overhealing_done: 0,
      absorbing_done: 0,
      leftover_absorb: 0,
      damage_reduced: 0,
    }
    self.resources_hash = {
      mana_spent: 0,
      heal_per_mana: {},
    }
    self.cooldowns_hash = {

    }
    @check_abc = true
    self.save
  end

  # settings

  def show_resources
    return [ResourceType::MANA]
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def in_progress?
    return true
  end

end