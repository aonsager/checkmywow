class FightParse::Shaman::Enhancement < FightParse
  include Filterable
  self.table_name = :fp_shaman_enh

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 3
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
      stormbringer_procs: 0,
      stormbringer_used: 0,
      hothand_procs: 0,
      hothand_used: 0,
    }
    self.resources_hash = {
      maelstrom_gain: 0,
      maelstrom_waste: 0,
      maelstrom_abilities: {},
      maelstrom_damage: 0,
      maelstrom_spent: 0,
      maelstrom_spend: {},
      landslide_uptime: 0,
      fury_of_air_uptime: 0,
      frostbrand_uptime: 0,
      flametongue_uptime: 0,
      lightning_crash_uptime: 0,
    }
    self.cooldowns_hash = {
      doomwinds_damage: 0,
      feral_damage: 0,
      ascendance_damage: 0,
    }
    @resources = {
      "r#{ResourceType::MAELSTROM}" => 0,
      "r#{ResourceType::MAELSTROM}_max" => self.max_maelstrom,
    }
    @maelstrom = 0
    @stormbringer_timestamp = 0
    @feral_ids = []
    self.save
  end

  # settings

  def spell_name(id)
    return {
      218825 => 'Boulderfist',
      201897 => 'Boulderfist',
      346035 => 'Boulderfist',
      193786 => 'Rockbiter',
      204945 => 'Doom Winds',
      51533 => 'Feral Spirit',
      198506 => 'Feral Spirit',
      201898 => 'Windsong',
      114051 => 'Ascendance',
      32175 => 'Stormstrike',
      17364 => 'Stormstrike',
      115357 => 'Stormstrike',
      115356 => 'Stormstrike', #Windstrike
      197992 => 'Landslide',
      202004 => 'Landslide',
      210853 => 'Hailstorm',
      196834 => 'Frostbrand',
      193796 => 'Flametongue',
      194084 => 'Flametongue',
      187874 => 'Crash Lightning',
      188196 => 'Lightning Bolt',
      187837 => 'Lightning Bolt',
      215785 => 'Hot Hand',
      201900 => 'Hot Hand',
      60103 => 'Lava Lash',
      201845 => 'Stormbringer',
      201846 => 'Stormbringer',
      192234 => 'Tempest',
      210727 => 'Overcharge',
      190185 => 'Maelstrom (Feral Spirit)',
      188089 => 'Earthen Spike',
      198293 => 'Wind Strikes',
      197211 => 'Fury of Air',
      197385 => 'Fury of Air',
      242284 => 'Lightning Crash',

    }[id] || super(id)
  end

  SET_IDS = {
    20 => [147175, 147176, 147177, 147178, 147179, 147180],
  }

  def track_casts
    local = {}
    local['Ascendance'] = {cd: 180} if talent(6) == 'Ascendance'
    local['Feral Spirit'] = {cd: 120}
    local['Doom Winds'] = {cd: 60}
    local['Windsong'] = {cd: 45} if talent(0) == 'Windsong'
    local['Earthen Spike'] = {cd: 20} if talent(6) == 'Earthen Spike'
    local['Stormstrike'] = {cd: 15 * self.haste_reduction_ratio}
    local['Lightning Bolt'] = {cd: 12} if talent(4) == 'Overcharge'
    local['Rockbiter'] = {cd: 6 * self.haste_reduction_ratio, extra: 1}
    local['Rockbiter'][:cd] *= 0.85 if talent(6) == 'Boulderfist'
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Ascendance'] = {cd: 180} if talent(6) == 'Ascendance'
    bars['cd']['Feral Spirit'] = {cd: 120}
    bars['cd']['Doom Winds'] = {cd: 60}
    bars['cd']['Windsong'] = {cd: 45} if talent(0) == 'Windsong'
    return bars
  end

  def uptime_abilities
    return {
      'Stormbringer' => {},
      'Hot Hand' => {},
    }
  end

  def buff_abilities
    return {
      'Landslide' => {},
      'Fury of Air' => {},
      'Frostbrand' => {},
      'Flametongue' => {},
      'Lightning Crash' => {},
    }
  end

  def cooldown_abilities
    local = {
      'Ascendance' => {kpi_hash: {damage_done: 0}},
      'Feral Spirit' => {kpi_hash: {damage_done: 0}},
      'Doom Winds' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Ascendance' => {},
      'Doom Winds' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::MAELSTROM]
  end

  # getters

  def max_maelstrom
    return 150
  end  

  # event handlers
  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Stormstrike' && @uptimes['Stormbringer'][:active]
      self.kpi_hash[:stormbringer_used] += 1
    elsif ability_name == 'Lava Lash' && @uptimes['Hot Hand'][:active]
      self.kpi_hash[:hothand_used] += 1
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::MAELSTROM
        @maelstrom = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        if resource['cost'].to_i > 0
          self.resources_hash[:maelstrom_spend][ability_name] ||= {name: ability_name, spent: 0, damage: 0}
          self.resources_hash[:maelstrom_spend][ability_name][:spent] += resource['cost'].to_i
        elsif ability_name == 'Lightning Bolt' && talent(4) == 'Overcharge'
          # logs don't show Maelstrom usage, so add it manually
          cost = [resource['amount'].to_i, 40].min
          self.resources_hash[:maelstrom_spend][ability_name] ||= {name: ability_name, spent: 0, damage: 0}
          self.resources_hash[:maelstrom_spend][ability_name][:spent] += cost
        end
      end
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if self.resources_hash[:maelstrom_spend].has_key?(ability_name)
      self.resources_hash[:maelstrom_spend][ability_name][:damage] += event['amount'].to_i
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Stormbringer' || ability_name == 'Wind Strikes'
      # ignore procs less than 0.1s apart
      if event['timestamp'].to_i - @stormbringer_timestamp >= 100
        self.kpi_hash[:stormbringer_procs] += 1
        @stormbringer_timestamp = event['timestamp']
      end
    elsif ability_name == 'Hot Hand'
      self.kpi_hash[:hothand_procs] += 1
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::MAELSTROM
      if event['resourceChange'].to_i > 0
        gain_maelstrom(ability_name, event['resourceChange'].to_i) 
      elsif ability_name == 'Healing Surge'
        self.resources_hash[:maelstrom_spend]['Healing Surge'] ||= {name: ability_name, spent: 0, damage: 0}
        self.resources_hash[:maelstrom_spend]['Healing Surge'][:spent] += -1 * event['resourceChange'].to_i
      end
    end
  end

  def gain_maelstrom(ability_name, gain)
    maelstrom_waste = [@maelstrom + gain - self.max_maelstrom, 0].max
    maelstrom_gain = gain - maelstrom_waste
    @maelstrom += maelstrom_gain
    self.resources_hash[:maelstrom_gain] += maelstrom_gain
    self.resources_hash[:maelstrom_waste] += maelstrom_waste
    self.resources_hash[:maelstrom_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
    self.resources_hash[:maelstrom_abilities][ability_name][:gain] += maelstrom_gain
    self.resources_hash[:maelstrom_abilities][ability_name][:waste] += maelstrom_waste
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if ability_name == 'Feral Spirit'
      if @cooldowns['Feral Spirit'][:active] && !@cooldowns['Feral Spirit'][:temp]
        drop_cooldown('Feral Spirit', @cooldowns['Feral Spirit'][:cp].ended_at || event['timestamp'])
      end
      gain_cooldown('Feral Spirit', event['timestamp'], {damage_done: 0})
      @feral_ids << target_id unless @feral_ids.include?(target_id)
    end
  end

  def pet_damage_event(event)
    super
    return if event['targetIsFriendly']
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if @feral_ids.include?(event['sourceID'])
      amount = event['amount'].to_i
      @cooldowns['Feral Spirit'][:cp].kpi_hash[:damage_done] = @cooldowns['Feral Spirit'][:cp].kpi_hash[:damage_done].to_i + amount
      @cooldowns['Feral Spirit'][:cp].details_hash[@actors[target_id]] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns['Feral Spirit'][:cp].details_hash[@actors[target_id]][:damage] += event['amount'].to_i
      @cooldowns['Feral Spirit'][:cp].details_hash[@actors[target_id]][:hits] += 1
      @cooldowns['Feral Spirit'][:cp].ended_at = event['timestamp']
    end
  end

  def clean
    super
    self.cooldown_parses.where('started_at = ended_at').destroy_all
    self.resources_hash[:landslide_uptime] = @kpis['Landslide'].first[:uptime].to_i rescue 0
    self.resources_hash[:fury_of_air_uptime] = @kpis['Fury of Air'].first[:uptime].to_i rescue 0
    self.resources_hash[:frostbrand_uptime] = @kpis['Frostbrand'].first[:uptime].to_i rescue 0
    self.resources_hash[:flametongue_uptime] = @kpis['Flametongue'].first[:uptime].to_i rescue 0
    self.resources_hash[:lightning_crash_uptime] = @kpis['Lightning Crash'].first[:uptime].to_i rescue 0
    if self.resources_hash[:maelstrom_spend].has_key?('Fury of Air')
      self.resources_hash[:maelstrom_spend]['Fury of Air'][:spent] = (self.resources_hash[:fury_of_air_uptime].to_i / 1000) * 3 + 3
    end
    self.resources_hash[:maelstrom_spend].each do |key, spell|
      self.resources_hash[:maelstrom_damage] += spell[:damage].to_i
      self.resources_hash[:maelstrom_spent] += spell[:spent].to_i
    end
    self.cooldowns_hash[:doomwinds_damage] = @kpis['Doom Winds'].map{|kpi| kpi[:damage_done].to_i + kpi[:extra_damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:feral_damage] = @kpis['Feral Spirit'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:ascendance_damage] = @kpis['Ascendance'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.save
  end

end