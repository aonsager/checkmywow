class FightParse::Shaman::Elemental < FightParse
  include Filterable
  self.table_name = :fp_shaman_ele

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
      stormkeeper_possible: 0,
      stormkeeper_buffed: 0,
      lavaburst_casts: 0,
      lavaburst_good: 0,
      lavaburst_badcasts: [],
      chainlightning_casts: 0,
      chainlightning_good: 0,
      chainlightning_badcasts: [],
    }
    self.resources_hash = {
      maelstrom_gain: 0,
      maelstrom_waste: 0,
      maelstrom_abilities: {},
      maelstrom_damage: 0,
      maelstrom_spent: 0,
      maelstrom_spend: {},
      flameshock_uptime: 0,
      flameshock_downtime: 0,
      earthshock_good: 0,
      earthshock_bad: 0,
      earthshock_casts: [],
      icefury_possible: 0,
      icefury_buffed: 0,
      totem_uptime: 0,
    }
    self.cooldowns_hash = {
      stormkeeper_damage: 0,
      ascendance_damage: 0,
      elemental_damage: 0,
    }
    @check_abc = true
    @resources = {
      "r#{ResourceType::MAELSTROM}" => 0,
      "r#{ResourceType::MAELSTROM}_max" => self.max_maelstrom,
    }
    @maelstrom = 0
    @chain = 0
    @chain_target = nil
    self.save
  end

  # settings

  def pet_name(id)
    return {
      15438 => 'Greater Fire Elemental',
      61029 => 'Primal Fire Elemental',
      77936 => 'Greater Storm Elemental',
      77942 => 'Primal Storm Elemental',
    }[id]
  end

  def spell_name(id)
    return {
      188389 => 'Flame Shock',
      8042 => 'Earth Shock',
      51505 => 'Lava Burst',
      117014 => 'Elemental Blast',
      210714 => 'Icefury',
      196840 => 'Frost Shock',
      205495 => 'Stormkeeper',
      114050 => 'Ascendance',
      16166 => 'Elemental Mastery',
      118291 => 'Fire Elemental',
      198067 => 'Fire Elemental',
      192249 => 'Storm Elemental',
      188196 => 'Lightning Bolt',
      188443 => 'Chain Lightning',
      114074 => 'Lava Beam',
      217891 => 'Lava Beam',
      16164 => 'Elemental Focus',
      16246 => 'Elemental Focus',
      210657 => 'Ember Totem',
      210643 => 'Totem Mastery',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    if talent(5) == 'Storm Elemental'
      local['Storm Elemental'] = {cd: 300, reduction: self.cooldowns_hash[:fire_elemental_reduction]}
    else
      local['Fire Elemental'] = {cd: 300, reduction: self.cooldowns_hash[:fire_elemental_reduction]}
    end
    local['Ascendance'] = {cd: 180} if talent(6) == 'Ascendance'
    local['Elemental Mastery'] = {cd: 120} if talent(5) == 'Elemental Mastery'
    local['Stormkeeper'] = {cd: 60}
    local['Icefury'] = {cd: 30} if talent(4) == 'Icefury'
    local['Elemental Blast'] = {cd: 12} if talent(3) == 'Elemental Blast'
    local['Lava Burst'] = {cd: 8}
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Ascendance'] = {cd: 180} if talent(6) == 'Ascendance'
    bars['cd']['Elemental Mastery'] = {cd: 180} if talent(5) == 'Elemental Mastery'
    bars['cd']['Stormkeeper'] = {cd: 60}
    return bars
  end

  def uptime_abilities
    return {
      'Icefury' => {},
      'Elemental Focus' => {},
    }
  end

  def debuff_abilities
    return {
      'Flame Shock' => {},
    }
  end

  def buff_abilities
    return {
      'Ember Totem' => {},
    }
  end

  def cooldown_abilities
    local = {
      'Ascendance' => {kpi_hash: {damage_done: 0}},
      'Elemental Mastery' => {kpi_hash: {damage_done: 0}},
      'Stormkeeper' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Ascendance' => {spells: ['Lava Burst', 'Lava Beam']},
      'Stormkeeper' => {spells: ['Lightning Bolt', 'Chain Lightning']},
      'Elemental Mastery' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::MAELSTROM]
  end

  # getters

  def max_maelstrom
    return 125
  end  

  # event handlers
  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Chain Lightning'
      self.kpi_hash[:chainlightning_casts] += 1
      self.kpi_hash[:chainlightning_badcasts] << @chain_target unless @chain_target.nil?
      @chain = 0
      @chain_target = nil
    elsif ability_name == 'Lava Burst'
      self.kpi_hash[:lavaburst_casts] += 1
    elsif ability_name == 'Earth Shock'
      self.resources_hash[:earthshock_casts] << {timestamp: event['timestamp'], msg: "Earth Shock cast with #{@maelstrom} Maelstrom.#{' Elemental Focus was active' if @uptimes['Elemental Focus'][:active]}"}
      if @maelstrom >= 117
        self.resources_hash[:earthshock_good] += 1
        self.resources_hash[:earthshock_casts].last[:class] = 'green'
      else
        self.resources_hash[:earthshock_bad] += 1
        self.resources_hash[:earthshock_casts].last[:class] = 'red'
      end
    end
    if is_active?('Stormkeeper', event['timestamp']) && ['Lightning Bolt', 'Chain Lightning'].include?(ability_name)
      self.kpi_hash[:stormkeeper_buffed] += 1
    end
    if @uptimes['Icefury'][:active] && ability_name == 'Frost Shock'
      self.resources_hash[:icefury_buffed] += 1
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::MAELSTROM
        @maelstrom = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        if resource['cost'].to_i > 0
          self.resources_hash[:maelstrom_spend][ability_name] ||= {name: ability_name, spent: 0, damage: 0}
          self.resources_hash[:maelstrom_spend][ability_name][:spent] += resource['cost'].to_i
        end
      end
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Chain Lightning'
      @chain += 1
      if @chain == 1
        @chain_target = {timestamp: event['timestamp'], msg: "Chain Lightning only hit #{@actors[target_id]}"}
      elsif @chain == 2 
        self.kpi_hash[:chainlightning_good] += 1 
        @chain_target = nil
      end
    elsif ability_name == 'Lava Burst'
      if @debuffs['Flame Shock'].has_key?(target_key) && @debuffs['Flame Shock'][target_key][:active]
        self.kpi_hash[:lavaburst_good] += 1
      else
        self.kpi_hash[:lavaburst_badcasts] << {timestamp: event['timestamp'], msg: "Lava Burst cast on #{@actors[target_id]} with no Flame Shock"}
      end
    end
    if self.resources_hash[:maelstrom_spend].has_key?(ability_name)
      self.resources_hash[:maelstrom_spend][ability_name][:damage] += event['amount'].to_i
    end

  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Stormkeeper'
      self.kpi_hash[:stormkeeper_possible] += 3
    elsif ability_name == 'Icefury'
      self.resources_hash[:icefury_possible] += 4
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

  def clean
    super
    self.kpi_hash[:chainlightning_badcasts] << @chain_target unless @chain_target.nil?
    self.cooldown_parses.where('started_at = ended_at').destroy_all
    self.debuff_parses.where(name: 'Flame Shock').each do |debuff|
      self.resources_hash[:flameshock_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:flameshock_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.resources_hash[:maelstrom_spend].each do |key, spell|
      self.resources_hash[:maelstrom_damage] += spell[:damage].to_i
      self.resources_hash[:maelstrom_spent] += spell[:spent].to_i
    end
    self.resources_hash[:totem_uptime] = @kpis['Ember Totem'].first[:uptime].to_i unless @kpis['Ember Totem'].nil?
    self.cooldowns_hash[:ascendance_damage] = @kpis['Ascendance'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:stormkeeper_damage] = @kpis['Stormkeeper'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:elemental_damage] = [@pet_kpis['Greater Fire Elemental'], @pet_kpis['Greater Storm Elemental'], @pet_kpis['Primal Fire Elemental'], @pet_kpis['Primal Storm Elemental']].compact.reduce([], :|).map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.save
  end

end