class FightParse::Druid::Balance < FightParse
  include Filterable
  self.table_name = :fp_druid_balance

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 3
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,

    }
    self.resources_hash = {
      capped_time: 0,
      astralpower_gained: 0,
      astralpower_wasted: 0,
      astralpower_abilities: {},
      lunar_gained: 0,
      lunar_used: 0,
      lunar_fails: [],
      solar_gained: 0,
      solar_used: 0,
      solar_fails: [],
      moonfire_uptime: 0,
      moonfire_downtime: 0,
      sunfire_uptime: 0,
      sunfire_downtime: 0,
      stellar_uptime: 0,
      stellar_downtime: 0,
    }
    self.cooldowns_hash = {
      starfall_damage: 0,
      starfall_dot_damage: 0,
      celestial_damage: 0,
      incarnation_damage: 0,
      fury_damage: 0,
      ap_per_fury: 0,
      force_damage: 0,
    }
    @resources = {
      "r#{ResourceType::ASTRALPOWER}" => 0,
      "r#{ResourceType::ASTRALPOWER}_max" => self.max_astralpower,
    }
    @check_abc = true
    @astralpower = 0
    @lunar_stacks = 0
    @solar_stacks = 0
    @treant_ids = []
    self.save
  end

  # settings

  def buff_abilities
    return {
      'Lunar Empowerment' => {},
      'Solar Empowerment' => {},
    }
  end

  def debuff_abilities
    return {
      'Moonfire' => {},
      'Sunfire' => {},
      'Stellar Flare' => {},
      'Stellar Empowerment' => {},
    }
  end

  def cooldown_abilities
    local = {
      'Celestial Alignment' => {kpi_hash: {damage_done: 0}},
      'Incarnation: Chosen of Elune' => {kpi_hash: {damage_done: 0}},
      'Fury of Elune' => {kpi_hash: {damage_done: 0, astralpower_gained: 0, astralpower_wasted: 0}},
      'Starfall' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Fury of Elune' => {channel: true},
      'Starfall' => {channel: true},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Celestial Alignment' => {percent: 0.3},
      'Incarnation: Chosen of Elune' => {percent: 0.35},
    }
    return super.merge local
  end

  def stellar_empowerment
    return 0.2
  end

  def max_astralpower
    return 1300
  end

  # getters

  def spell_name(id)
    return {
      194154 => 'Lunar Strike',
      190984 => 'Solar Wrath',
      8921 => 'Moonfire',
      164812 => 'Moonfire',
      93402 => 'Sunfire',
      164815 => 'Sunfire',
      78674 => 'Starsurge',
      191034 => 'Starfall',
      164547 => 'Lunar Empowerment',
      164545 => 'Solar Empowerment',
      202767 => 'New Moon',
      202768 => 'Half Moon',
      202771 => 'Full Moon',
      194223 => 'Celestial Alignment',
      102560 => 'Incarnation: Chosen of Elune',
      197637 => 'Stellar Empowerment',
      205636 => 'Force of Nature',
      202425 => 'Warrior of Elune',
      202347 => 'Stellar Flare',
      202359 => 'Astral Communion',
      202770 => 'Fury of Elune',
    }[id] || super(id)
  end

  def pet_name(id)
    return {
      103822 => 'Treant',
    }[id]
  end

  def track_casts
    local = {}
    if talent(4) == 'Incarnation: Chosen of Elune' 
      local['Incarnation: Chosen of Elune'] = {cd: 180} 
    else
      local['Celestial Alignment'] = {cd: 180}
    end
    local['Fury of Elune'] == {cd: 90} if talent(6) == 'Fury of Elune'
    local['Astral Communion'] == {cd: 80} if talent(5) == 'Astral Communion'
    if talent(0) == 'Force of Nature'
      local['Force of Nature'] = {cd: 60}
    elsif talent(0) == 'Warrior of Elune'
      local['Warrior of Elune'] = {cd: 45}
    end
    local['Moon'] = {cd: 15, extra: 2}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Celestial Alignment'] = {cd: 180} if talent(4) != 'Incarnation: Chosen of Elune' 
    bars['cd']['Incarnation: Chosen of Elune'] = {cd: 180} if talent(4) == 'Incarnation: Chosen of Elune' 
    bars['cd']['Fury of Elune'] = {cd: 90} if talent(6) == 'Fury of Elune'
    bars['cd']['Force of Nature'] = {cd: 60} if talent(0) == 'Force of Nature'
    bars['cd']['Starfall'] = {optional: true}

    return bars
  end

  def track_resources
    return [ResourceType::ASTRALPOWER]
  end

  # event handlers

  def begin_cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ['New Moon', 'Half Moon', 'Full Moon'].include?(ability_name)
      @casts_details.pop if ['New Moon', 'Half Moon', 'Full Moon'].include?(@casts_details.last['ability'])
      save_cast_detail(event, 'Moon', 'begin_cast', "Begin casting #{ability_name}")
    end
  end

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Starsurge'
      self.resources_hash[:lunar_gained] += 1
      self.resources_hash[:solar_gained] += 1
      if @lunar_stacks == 3
        self.resources_hash[:lunar_fails] << {timestamp: event['timestamp'], msg: "Cast Starsurge with 3 stacks of Lunar Empowerment"}
      else
        @lunar_stacks += 1
      end
      if @solar_stacks == 3
        self.resources_hash[:solar_fails] << {timestamp: event['timestamp'], msg: "Cast Starsurge with 3 stacks of Solar Empowerment"}
      else
        @solar_stacks += 1
      end
    elsif ability_name == 'Lunar Strike'
      if @lunar_stacks > 0
        self.resources_hash[:lunar_used] += 1
        @lunar_stacks -= 1
      else
        self.resources_hash[:lunar_fails] << {timestamp: event['timestamp'], msg: "Cast Lunar Strike with no stacks of Lunar Empowerment"}
      end
    elsif ability_name == 'Solar Wrath' && @solar_stacks > 0
      self.resources_hash[:solar_used] += 1
      @solar_stacks -= 1 unless @solar_stacks == 0
    elsif ['New Moon', 'Half Moon', 'Full Moon'].include?(ability_name)
      self.casts_hash['Moon'] << event['timestamp']
      @casts_details.pop if ['New Moon', 'Half Moon', 'Full Moon'].include?(@casts_details.last['ability'])
      save_cast_detail(event, 'Moon', 'cast', "Cast #{ability_name}")
      @cds.delete(ability_name)
      @cds['Moon'] = (event['timestamp'] + self.track_casts['Moon'][:cd] * 1000).to_i
    elsif ability_name == 'Force of Nature'
      drop_cooldown('Force of Nature', @cooldowns['Force of Nature'][:cp].ended_at) if @cooldowns.has_key?('Force of Nature') && @cooldowns['Force of Nature'][:active]
      gain_cooldown('Force of Nature', event['timestamp'], {damage_done: 0})
    end

    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::ASTRALPOWER
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
        @astralpower = resource['amount'].to_i
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::ASTRALPOWER
        @astralpower = resource['amount'].to_i
        max_astralpower = resource['max'].to_i
      end
    end

    if event['resourceChangeType'] == ResourceType::ASTRALPOWER
      ap_waste = [@astralpower + event['resourceChange'].to_i - max_astralpower, 0].max
      ap_gain = event['resourceChange'].to_i - ap_waste
      self.resources_hash[:astralpower_gained] += ap_gain
      self.resources_hash[:astralpower_wasted] += ap_waste
      self.resources_hash[:astralpower_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:astralpower_abilities][ability_name][:gain] += ap_gain
      self.resources_hash[:astralpower_abilities][ability_name][:waste] += ap_waste
      if @cooldowns['Fury of Elune'][:active]
        @cooldowns['Fury of Elune'][:cp].kpi_hash[:astralpower_gained] += ap_gain
        @cooldowns['Fury of Elune'][:cp].details_hash[ability_name] ||= {name: ability_name, casts: 0, ap_gained: 0}
        @cooldowns['Fury of Elune'][:cp].details_hash[ability_name][:casts] += 1
        @cooldowns['Fury of Elune'][:cp].details_hash[ability_name][:ap_gained] += ap_gain
      end
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if @debuffs.has_key?('Stellar Empowerment') && @debuffs['Stellar Empowerment'].has_key?(target_key) && @debuffs['Stellar Empowerment'][target_key][:active] && event['tick']
      if @cooldowns['Starfall'][:active]
        amount = event['amount'] - (event['amount'] / (1 + self.stellar_empowerment)).to_i
        @cooldowns['Starfall'][:cp].kpi_hash[:extra_damage] = @cooldowns['Starfall'][:cp].kpi_hash[:extra_damage].to_i + amount
        @cooldowns['Starfall'][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0, extra_damage: 0, extra_hits: 0}
        @cooldowns['Starfall'][:cp].details_hash[target_key][:extra_damage] = @cooldowns['Starfall'][:cp].details_hash[target_key][:extra_damage].to_i + amount
        @cooldowns['Starfall'][:cp].details_hash[target_key][:extra_hits] = @cooldowns['Starfall'][:cp].details_hash[target_key][:extra_hits].to_i + 1
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Fury of Elune'
      @cooldowns['Fury of Elune'][:cp].kpi_hash[:astralpower_at_start] = @astralpower
    end
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    @treant_ids << target_id if ability_name == 'Force of Nature'
  end

  def pet_damage_event(event)
    super
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if @treant_ids.include?(event['sourceID'])
      @cooldowns['Force of Nature'][:cp].kpi_hash[:damage_done] += event['amount'].to_i
      @cooldowns['Force of Nature'][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns['Force of Nature'][:cp].details_hash[target_key][:damage] += event['amount'].to_i
      @cooldowns['Force of Nature'][:cp].details_hash[target_key][:hits] += 1
      @cooldowns['Force of Nature'][:cp].ended_at = event['timestamp']
      @cooldowns['Force of Nature'][:cp].save unless @cooldowns['Force of Nature'][:active]
    end
  end

  def clean
    super
    self.cooldowns_hash[:celestial_damage] = @kpis['Celestial Alignment'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:incarnation_damage] = @kpis['Incarnation: Chosen of Elune'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:starfall_damage] = @kpis['Starfall'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:starfall_dot_damage] = @kpis['Starfall'].map{|kpi| kpi[:extra_damage]}.sum rescue 0
    self.cooldowns_hash[:fury_damage] = @kpis['Fury of Elune'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:ap_per_fury] = @kpis['Fury of Elune'].map{|kpi| kpi[:astralpower_at_start].to_i + kpi[:astralpower_gained].to_i}.sum / @kpis['Fury of Elune'].count rescue 0
    self.debuff_parses.where(name: 'Moonfire').each do |debuff|
      # ignore mobs active for less than 10 seconds
      next if debuff.kpi_hash[:uptime].to_i + debuff.kpi_hash[:downtime].to_i < 10000
      self.resources_hash[:moonfire_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:moonfire_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.debuff_parses.where(name: 'Sunfire').each do |debuff|
      # ignore mobs active for less than 10 seconds
      next if debuff.kpi_hash[:uptime].to_i + debuff.kpi_hash[:downtime].to_i < 10000
      self.resources_hash[:sunfire_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:sunfire_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.debuff_parses.where(name: 'Stellar Flare').each do |debuff|
      # ignore mobs active for less than 10 seconds
      next if debuff.kpi_hash[:uptime].to_i + debuff.kpi_hash[:downtime].to_i < 10000
      self.resources_hash[:stellar_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:stellar_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    @pet_kpis.each do |pet_name, kpis|
      if pet_name == 'Treant'
        self.cooldowns_hash[:force_damage] = kpis.map{|kpi| kpi[:damage_done]}.sum rescue 0
      end
    end
    if @lunar_stacks > 0
      self.resources_hash[:lunar_fails] << {timestamp: self.ended_at, msg: "Ended the fight with #{@lunar_stacks} stacks", class: ''}
    end
    if @solar_stacks > 0
      self.resources_hash[:solar_fails] << {timestamp: self.ended_at, msg: "Ended the fight with #{@solar_stacks} stacks", class: ''}
    end

    self.save
  end

end