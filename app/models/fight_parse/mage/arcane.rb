class FightParse::Mage::Arcane < FightParse
  include Filterable
  self.table_name = :fp_mage_arcane
  
  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
    }
    self.resources_hash = {
      nether_ac: {0=>0, 1=>0, 2=>0, 3=>0, 4=>0},
      nether_uptime: 0,
      burn_uptime: 0,
      burn_ac4_uptime: 0,
      avg_burn: 0,
      avg_evocation: 0,
    }
    self.cooldowns_hash = {
      ap_damage: 0,
      rune_damage: 0,
    }
    @resources = {
      "r#{ResourceType::MANA}" => 1,
      "r#{ResourceType::MANA}_max" => 1,
      "r#{ResourceType::ARCANECHARGES}" => 0,
      "r#{ResourceType::ARCANECHARGES}_max" => self.max_arcane,
    }
    @arcane = 0
    @check_abc = true
    self.save
  end

  # settings

  def spell_name(id)
    return {
      116011 => 'Rune of Power',
      162113 => 'Rune of Power',
      162112 => 'Rune of Power',
      116014 => 'Rune of Power',
      114954 => 'Nether Tempest',
      114923 => 'Nether Tempest',
      12042 => 'Arcane Power',
      12051 => 'Evocation',
      135449 => 'Evocation',
      12043 => 'Presence of Mind',
      29976 => 'Presence of Mind',
      7268 => 'Arcane Missiles',
      5143 => 'Arcane Missiles',
      79683 => 'Arcane Missiles!',
      44425 => 'Arcane Barrage',
      30451 => 'Arcane Blast',
      55342 => 'Mirror Image',
      157980 => 'Supernova',
      205032 => 'Charged Up',
      153626 => 'Arcane Orb',
      221076 => 'Mark of Aluneth',
      211088 => 'Mark of Aluneth',
      224968 => 'Mark of Aluneth',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Mirror Image'] = {cd: 120} if talent(2) == 'Mirror Image'
    local['Arcane Power'] = {cd: 90}
    local['Evocation'] = {cd: 90}
    local['Mark of Aluneth'] = {cd: 60}
    local['Rune of Power'] = {cd: 40, extra: 1} if talent(2) == 'Rune of Power'
    local['Charged Up'] = {cd: 40}if talent(3) == 'Charged Up'
    local['Supernova'] = {cd: 25} if talent(3) == 'Supernova'
    local['Arcane Orb'] = {cd: 20} if talent(6) == 'Arcane Orb'
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['pet']['Mirror Image'] = {cd: 120}  if talent(2) == 'Mirror Image'
    bars['cd']['Evocation'] = {cd: 90}
    bars['cd']['Arcane Power'] = {cd: 90}
    bars['cd']['Rune of Power'] = {cd: 40, extra: 1} if talent(2) == 'Rune of Power'
    
    return bars
  end

  def debuff_abilities
    local = {
      'Nether Tempest' => {ac_charges: 0},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Arcane Power' => {kpi_hash: {damage_done: 0, start_mana: 100, end_mana: 0}},
      'Rune of Power' => {kpi_hash: {damage_done: 0}},
      'Evocation' => {kpi_hash: {start_mana: 0, end_mana: 0}},
      'Conserve Phase' => {kpi_hash: {}},
      'Burn Phase' => {kpi_hash: {ac4_uptime: 0, start_mana: 100, end_mana: 0}},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Arcane Power' => {percent: 0.3},
      'Rune of Power' => {percent: 0.4},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::MANA, ResourceType::ARCANECHARGES]
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  # getters

  def max_arcane
    return 4
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    source_key = "#{event['sourceID'].to_i}-#{event['sourceInstance'].to_i}"
    if ability_name == 'Nether Tempest'
      self.resources_hash[:nether_ac][@arcane] += 1
    elsif ability_name == 'Arcane Barrage' 
      @arcane = 0
      @resources["r#{ResourceType::ARCANECHARGES}"] = 0
      if @cooldowns['Burn Phase'][:active] && @cooldowns['Burn Phase'][:ac4]
        @cooldowns['Burn Phase'][:cp].kpi_hash[:ac4_uptime] += event['timestamp']
        @cooldowns['Burn Phase'][:ac4] = false
      end
    end
    # (event['classResources'] || []).each do |resource|
    #   @arcane = [resource['amount'].to_i - resource['cost'].to_i, 0].max if resource['type'] == ResourceType::ARCANECHARGES
    # end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::ARCANECHARGES
      arcane_waste = [@arcane + event['resourceChange'].to_i - self.max_arcane, 0].max
      arcane_gain = event['resourceChange'].to_i - arcane_waste
      @arcane += arcane_gain
      if @arcane == 4 && @cooldowns['Burn Phase'][:active] && !@cooldowns['Burn Phase'][:ac4]
        @cooldowns['Burn Phase'][:cp].kpi_hash[:ac4_uptime] -= event['timestamp']
        @cooldowns['Burn Phase'][:ac4] = true
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Arcane Power'
      @cooldowns['Arcane Power'][:cp].kpi_hash[:start_mana] = 100 * @resources['r0'] / @resources['r0_max']
      end_conserve_phase(event['timestamp']) if @cooldowns['Conserve Phase'][:active]
      start_burn_phase(event['timestamp'])
    elsif ability_name == 'Evocation'
      @cooldowns['Evocation'][:cp].kpi_hash[:start_mana] = 100 * @resources['r0'] / @resources['r0_max']
      end_burn_phase(event['timestamp'])
    end
  end

  def lose_self_buff_event(event, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Arcane Power'
      @cooldowns['Arcane Power'][:cp].kpi_hash[:end_mana] = 100 * @resources['r0'] / @resources['r0_max']
      @cooldowns['Arcane Power'][:cp].save
    elsif ability_name == 'Evocation'
      @cooldowns['Evocation'][:cp].kpi_hash[:end_mana] = 100 * @resources['r0'] / @resources['r0_max']
      @cooldowns['Evocation'][:cp].save
      start_conserve_phase(event['timestamp'])
    end
  end

  def start_burn_phase(timestamp)
    gain_cooldown('Burn Phase', timestamp, {ac4_uptime: 0, start_mana: 100 * @resources['r0'] / @resources['r0_max'], end_mana: 0})
    if @arcane == 4
      @cooldowns['Burn Phase'][:cp].kpi_hash[:ac4_uptime] -= timestamp
      @cooldowns['Burn Phase'][:ac4] = true
    else
      @cooldowns['Burn Phase'][:ac4] = false
    end
  end

  def end_burn_phase(timestamp)
    start_burn_phase(self.started_at) if @cooldowns['Burn Phase'][:cp].nil?
    @cooldowns['Burn Phase'][:cp].kpi_hash[:end_mana] = 100 * @resources['r0'] / @resources['r0_max']
    if @arcane == 4
      @cooldowns['Burn Phase'][:cp].kpi_hash[:ac4_uptime] += timestamp
    end
    drop_cooldown('Burn Phase', timestamp, 'cd', true)

  end

  def start_conserve_phase(timestamp)
    gain_cooldown('Conserve Phase', timestamp, {uncapped_time: 0})
    @cooldowns['Conserve Phase'][:total_mana] = 0
    @cooldowns['Conserve Phase'][:mana_counts] = 0
    if @resources['r0'] < @resources['r0_max']
      # @cooldowns['Conserve Phase'][:cp].kpi_hash[:uncapped_time] -= timestamp
      @cooldowns['Conserve Phase'][:capped] = false
    else
      @cooldowns['Conserve Phase'][:capped] = true
    end
  end

  def end_conserve_phase(timestamp)
    if @resources['r0'] < @resources['r0_max']
      # @cooldowns['Conserve Phase'][:cp].kpi_hash[:uncapped_time] += timestamp
    end
    # @cooldowns['Conserve Phase'][:cp].kpi_hash[:avg_mana] = @cooldowns['Conserve Phase'][:total_mana] / @cooldowns['Conserve Phase'][:mana_counts] rescue 100
    drop_cooldown('Conserve Phase', timestamp, 'cd', true)
  end

  def clean
    end_conserve_phase(self.ended_at) if @cooldowns['Conserve Phase'][:active]
    end_burn_phase(self.ended_at) if @cooldowns['Burn Phase'][:active]

    super

    self.cooldown_parses.where(name: 'Burn Phase').each do |cd|
      next if cd.ended_at.nil? || cd.started_at.nil?
      self.resources_hash[:burn_uptime] += cd.ended_at - cd.started_at
      self.resources_hash[:burn_ac4_uptime] += cd.kpi_hash[:ac4_uptime]
    end
    # self.cooldown_parses.where(name: 'Conserve Phase').each do |cd|
    #   self.resources_hash[:cons_uptime] += cd.ended_at - cd.started_at
    #   self.resources_hash[:cons_uncapped_time] += cd.kpi_hash[:uncapped_time]
    # end
    self.resources_hash[:nether_uptime] = @uptimes['Nether Tempest'][:uptime] rescue 0
    self.resources_hash[:avg_evocation] = @kpis['Evocation'].map{|kpi| kpi[:end_mana] - kpi[:start_mana]}.sum / @kpis['Evocation'].size rescue 0
    self.resources_hash[:avg_burn] = @kpis['Burn Phase'].map{|kpi| kpi[:start_mana] - kpi[:end_mana]}.sum / @kpis['Burn Phase'].size rescue 0
    self.cooldowns_hash[:ap_damage] = @kpis['Arcane Power'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:rune_damage] = @kpis['Rune of Power'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.save
  end

end