class FightParse::Warrior::Fury < FightParse
  include Filterable
  self.table_name = :fp_warrior_fury

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      ragingblow_damage: 0,
      execute_damage: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      enrage_uptime: 0,
      meatcleaver_procs: 0,
      meatcleaver_uses: 0,
      meatcleaver_abilities: {},
    }
    self.cooldowns_hash = {
      dragonroar_damage: 0,
      battlecry_damage: 0,
      avatar_damage: 0,
      odyn_damage: 0,
    }
    @resources = {
      "r#{ResourceType::RAGE}" => 0,
      "r#{ResourceType::RAGE}_max" => 1000,
    }
    gain_cooldown('Execute', self.started_at, {damage_done: 0})
    gain_cooldown('Raging Blow', self.started_at, {damage_done: 0})
    self.save
  end

  # settings

  def uptime_abilities
    local = {
      'Meat Cleaver' => {},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Avatar' => {kpi_hash: {damage_done: 0}},
      'Battle Cry' => {kpi_hash: {damage_done: 0}},
      'Dragon Roar' => {kpi_hash: {damage_done: 0}},
      'Bladestorm' => {kpi_hash: {damage_done: 0}},
      'Odyn\'s Fury' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Bladestorm' => {channel: true},
      'Execute' => {channel: true},
      'Raging Blow' => {channel: true},
      'Odyn\'s Fury' => {},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Avatar' => {percent: 0.2},
      'Battle Cry' => {},
      'Dragon Roar' => {},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Enrage' => {},
    }
    return super.merge local
  end

  def track_casts
    local = {}
    local['Bladestorm'] = {cd: 90} if talent(6) == 'Bladestorm'
    local['Avatar'] = {cd: 90} if talent(2) == 'Avatar'
    local['Battle Cry'] = {cd: 60}
    local['Odyn\'s Fury'] = {cd: 45}
    local['Bloodbath'] = {cd: 30} if talent(5) == 'Bloodbath'
    local['Dragon Roar'] = {cd: 25} if talent(6) == 'Dragon Roar'
    local['Raging Blow'] = {cd: 4.5} if talent(5) == 'Inner Rage'
    local['Bloodthirst'] = {cd: 4.5}
    
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Bladestorm'] = {cd: 90} if talent(6) == 'Bladestorm'
    bars['cd']['Avatar'] = {cd: 90} if talent(2) == 'Avatar'
    bars['cd']['Battle Cry'] = {cd: 60}
    bars['cd']['Odyn\'s Fury'] = {cd: 45}
    bars['cd']['Dragon Roar'] = {cd: 25} if talent(6) == 'Dragon Roar'
    return bars
  end

  def track_resources
    return [ResourceType::RAGE]
  end

  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 2
  end

  # getters

  def spell_name(id)
    return {
      23881 => 'Bloodthirst',
      184361 => 'Enrage',
      184362 => 'Enrage',
      85288 => 'Raging Blow',
      100130 => 'Furious Slash',
      184367 => 'Rampage',
      118000 => 'Dragon Roar',
      1719 => 'Battle Cry',
      5308 => 'Execute',
      85739 => 'Meat Cleaver',
      46924 => 'Bladestorm',
      107574 => 'Avatar',
      12292 => 'Bloodbath',
      215573 => 'Inner Rage',
      205545 => 'Odyn\'s Fury',
    }[id] || super(id)
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    
    if @uptimes['Meat Cleaver'][:active] && ['Bloodthirst', 'Rampage'].include?(ability_name)
      self.resources_hash[:meatcleaver_uses] += 1
      self.resources_hash[:meatcleaver_abilities][ability_name] ||= {name: ability_name, casts: 0}
      self.resources_hash[:meatcleaver_abilities][ability_name][:casts] += 1
    end

    (event['classResources'] || []).each do |resource|
      check_resource_cap(resource['amount'], resource['max'], event['timestamp']) if resource['type'] == ResourceType::RAGE
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:meatcleaver_procs] += 1 if ability_name == 'Meat Cleaver'
  end

  def clean
    super
    self.cooldowns_hash[:avatar_damage] = @kpis['Avatar'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:dragonroar_damage] = @kpis['Dragon Roar'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:bladestorm_damage] = @kpis['Bladestorm'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:battlecry_damage] = @kpis['Battle Cry'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:odyn_damage] = @kpis['Odyn\'s Fury'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.kpi_hash[:ragingblow_damage] = @kpis['Raging Blow'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.kpi_hash[:execute_damage] = @kpis['Execute'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.resources_hash[:enrage_uptime] = @kpis['Enrage'].first[:uptime].to_i rescue 0
    self.save
  end

end