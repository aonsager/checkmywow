class FightParse::Shaman::Restoration < HealerParse
  include Filterable
  self.table_name = :fp_shaman_resto

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 3
  end

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
      chain_heal_good: 0,
      chain_heal_total: 0,
      chain_heal_hits: {1=>0, 2=>0, 3=>0, 4=>0, 5=>0},
      tidal_waves_buffed: 0,
      tidal_waves_unbuffed: 0,
      tidal_waves_spells: {'Healing Wave' => {buffed: 0, unbuffed: 0}, 'Healing Surge' => {buffed: 0, unbuffed: 0}},
      tidal_waves_procs: 0,
      tidal_waves_used: 0,
    }
    self.resources_hash = {
      mana_spent: 0,
      heal_per_mana: {},
      vigor_uptime: 0,
    }
    self.cooldowns_hash = {
      ascendance_healing: 0,
      ascendance_overhealing: 0,
      cloudburst_healing: 0,
      cloudburst_overhealing: 0,
      guidance_healing: 0,
      guidance_overhealing: 0,
      healing_tide_healing: 0,
      healing_tide_overhealing: 0,
      queen_healing: 0,
      queen_overhealing: 0,
      spirit_link_score: 0,
    }
    @check_abc = true
    @chain_heal_hits = 0
    @healing_tide_id = nil
    @spirit_link_id = nil
    @cloudburst_id = nil
    self.save
  end

  # settings

  def spell_name(id)
    return {
      61295 => 'Riptide',
      5394 => 'Healing Stream Totem',
      108280 => 'Healing Tide Totem',
      114942 => 'Healing Tide',
      73920 => 'Healing Rain',
      1064 => 'Chain Heal',
      51564 => 'Tidal Waves',
      53390 => 'Tidal Waves',
      98008 => 'Spirit Link Totem',
      98021 => 'Spirit Link',
      207778 => 'Gift of the Queen',
      77472 => 'Healing Wave',
      8004 => 'Healing Surge',
      197464 => 'Crashing Waves',
      108281 => 'Ancestral Guidance',
      137087 => 'Deluge',
      207400 => 'Ancestral Vigor',
      207401 => 'Ancestral Vigor',
      157153 => 'Cloudburst Totem',
      157503 => 'Cloudburst',
      114052 => 'Ascendance',
      207399 => 'Ancestral Protection Totem',
      198838 => 'Earthen Shield Totem',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Spirit Link Totem'] = {cd: 180}
    local['Healing Tide Totem'] = {cd: 180}
    local['Ascendance'] = {cd: 180} if talent(6) == 'Ascendance'
    local['Ancestral Guidance'] = {cd: 120} if talent(3) == 'Ancestral Guidance'
    local['Earthen Shield Totem'] = {cd: 60} if talent(4) == 'Earthen Shield Totem'
    local['Gift of the Queen'] = {cd: 30}
    local['Healing Stream Totem'] = {cd: 30}
    local['Cloudburst Totem'] = {cd: 30} if talent(5) == 'Cloudburst Totem'
    local['Wellspring'] = {cd: 20} if talent(6) == 'Wellspring'
    # local['Healing Rain'] = {cd: 10}
    local['Riptide'] = {cd: 6}
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['pet']['Spirit Link Totem'] = {cd: 180, color: 'orange'}
    bars['pet']['Healing Tide Totem'] = {cd: 180, color: 'orange'}
    bars['cd']['Ascendance'] = {cd: 180} if talent(6) == 'Ascendance'
    bars['heal']['Ancestral Guidance'] = {cd: 120} if talent(3) == 'Ancestral Guidance'
    bars['pet']['Earthen Shield Totem'] = {cd: 60, color: 'orange'} if talent(4) == 'Earthen Shield Totem'
    bars['heal']['Gift of the Queen'] = {cd: 30}
    bars['pet']['Healing Stream Totem'] = {cd: 30, color: 'orange'}
    bars['pet']['Cloudburst Totem'] = {cd: 30, color: 'orange'} if talent(5) == 'Cloudburst Totem'
    return bars
  end

  def cooldown_abilities
    local = {
      'Ascendance' => {kpi_hash: {healing_increase: 0, overhealing_increase: 0}},
    }
    return super.merge local
  end
  

  def healing_buff_abilities
    return {
      'Ascendance' => {},
    }
  end

  def healing_abilities
    local = [
      'Ancestral Guidance',
      'Gift of the Queen',
    ]
    return super + local
  end

  def buff_abilities
    local = {
      'Tidal Waves' => {},
    }
    return super.merge local
  end

  def external_buff_abilities
    local = {
      'Ancestral Vigor' => {},
      'Riptide' => {},
    }
    return super.merge local
  end

  def pet_name(id)
    return {
      59764 => 'Healing Tide Totem',
      53006 => 'Spirit Link Totem',
      78001 => 'Cloudburst Totem',
    }[id]
  end

  def show_resources
    return [ResourceType::MANA]
  end

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Chain Heal'
      self.kpi_hash[:chain_heal_hits][@chain_heal_hits] = self.kpi_hash[:chain_heal_hits][@chain_heal_hits].to_i + 1
      @chain_heal_hits = 0
      self.kpi_hash[:tidal_waves_procs] += 1
    elsif ability_name == 'Riptide'
      self.kpi_hash[:tidal_waves_procs] += (talent(3) == 'Crashing Waves' ? 2 : 1)
    elsif ability_name == 'Healing Wave' || ability_name == 'Healing Surge'
      if @buffs['Tidal Waves'][:active]
        self.kpi_hash[:tidal_waves_used] += 1
        self.kpi_hash[:tidal_waves_spells][ability_name][:buffed] += 1
      else
        self.kpi_hash[:tidal_waves_spells][ability_name][:unbuffed] += 1
      end
    end
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return unless @player_ids.include?(target_id)
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Chain Heal'
      @chain_heal_hits += 1
    elsif ability_name == 'Healing Tide' && @pets.has_key?(@healing_tide_id)
      @pets[@healing_tide_id][:pet].kpi_hash[:healing_done] = @pets[@healing_tide_id][:pet].kpi_hash[:healing_done].to_i + event['amount'].to_i
      @pets[@healing_tide_id][:pet].kpi_hash[:overhealing_done] = @pets[@healing_tide_id][:pet].kpi_hash[:overhealing_done].to_i + event['overheal'].to_i
      @pets[@healing_tide_id][:pet].details_hash[@actors[target_id]] ||= {name: @actors[target_id], healing: 0, overhealing: 0, hits: 0}
      @pets[@healing_tide_id][:pet].details_hash[@actors[target_id]][:healing] += event['amount'].to_i
      @pets[@healing_tide_id][:pet].details_hash[@actors[target_id]][:overhealing] += event['overheal'].to_i
      @pets[@healing_tide_id][:pet].details_hash[@actors[target_id]][:hits] += 1
      @pets[@healing_tide_id][:pet].ended_at = event['timestamp']
    end
    if @pets.has_key?(@cloudburst_id) && @pets[@cloudburst_id][:active]
      if ability_name == 'Cloudburst'
        @pets[@cloudburst_id][:pet].kpi_hash[:healing_done] += event['amount'].to_i
        @pets[@cloudburst_id][:pet].kpi_hash[:overhealing_done] += event['overheal'].to_i
        @pets[@cloudburst_id][:pet].ended_at = event['timestamp']
      else
        @pets[@cloudburst_id][:pet].details_hash[ability_name] ||= {healing_done: 0, overhealing_done: 0, hits: 0}
        @pets[@cloudburst_id][:pet].details_hash[ability_name][:healing_done] += event['amount'].to_i
        @pets[@cloudburst_id][:pet].details_hash[ability_name][:overhealing_done] += event['overheal'].to_i
        @pets[@cloudburst_id][:pet].details_hash[ability_name][:hits] += 1
      end
    end
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if ability_name == 'Healing Tide Totem'
      @healing_tide_id = target_id
    elsif ability_name == 'Spirit Link Totem'
      @spirit_link_id = target_id
      @pets[target_id][:pet].kpi_hash = {damage_done: 0, damage_ticks: 0, healing_done: 0, overhealing_done: 0, healing_ticks: 0, score: 0}
    elsif ability_name == 'Cloudburst Totem'
      @cloudburst_id = target_id
      @pets[target_id][:pet].name = 'Cloudburst Totem' # since the pet isn't listed as an actor'
      @pets[target_id][:pet].kpi_hash = {damage_done: 0, damage_ticks: 0, healing_done: 0, overhealing_done: 0}
    end
  end

  def pet_heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Spirit Link' && @pets.has_key?(event['sourceID'])
      @pets[event['sourceID']][:pet].kpi_hash[:healing_ticks] ||= 0
      @pets[event['sourceID']][:pet].kpi_hash[:healing_ticks] += 1
    end
  end

  def pet_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    target_id = event.has_key?('target') ? event['target']['id'] : event['targetID']
    if ability_name == 'Spirit Link' && @pets.has_key?(event['sourceID'])
      @pets[event['sourceID']][:pet].kpi_hash[:damage_done] += event['amount'].to_i + event['absorbed'].to_i
      @pets[event['sourceID']][:pet].kpi_hash[:damage_ticks] ||= 0
      @pets[event['sourceID']][:pet].kpi_hash[:damage_ticks] += 1
      @pets[event['sourceID']][:pet].details_hash[@actors[target_id]] ||= {name: @actors[target_id], healing: 0, overhealing: 0, hits: 0}
      @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:damage] ||= 0
      @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:damage] += event['amount'].to_i + event['absorbed'].to_i
      @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:hits] += 1
    end
  end

  def pet_death(id, timestamp)
    super
    if id == @spirit_link_id
      percent = 1.0 * @pets[id][:pet].kpi_hash[:damage_ticks].to_i / (@pets[id][:pet].kpi_hash[:damage_ticks].to_i + @pets[id][:pet].kpi_hash[:healing_ticks].to_i) rescue 0
      @pets[id][:pet].kpi_hash[:score] = (@pets[id][:pet].kpi_hash[:healing_done].to_i * percent).to_i rescue 0
      @pets[id][:pet].save
    end
  end

  def clean
    super
    @pet_kpis.each do |pet_name, kpis|
      if pet_name == 'Healing Tide Totem'
        self.cooldowns_hash[:healing_tide_healing] += kpis.map{|kpi| kpi[:healing_done]}.sum rescue 0
        self.cooldowns_hash[:healing_tide_overhealing] += kpis.map{|kpi| kpi[:overhealing_done]}.sum rescue 0
      elsif pet_name == 'Spirit Link Totem'
        self.cooldowns_hash[:spirit_link_score] += kpis.map{|kpi| kpi[:score]}.sum rescue 0
      elsif pet_name == 'Cloudburst Totem'
        self.cooldowns_hash[:cloudburst_healing] += kpis.map{|kpi| kpi[:healing_done]}.sum rescue 0
        self.cooldowns_hash[:cloudburst_overhealing] += kpis.map{|kpi| kpi[:overhealing_done]}.sum rescue 0
      end
    end
    self.kpi_hash[:tidal_waves_unbuffed] = self.kpi_hash[:tidal_waves_spells]['Healing Wave'][:unbuffed].to_i + self.kpi_hash[:tidal_waves_spells]['Healing Surge'][:unbuffed].to_i rescue 0
    self.kpi_hash[:tidal_waves_buffed] = self.kpi_hash[:tidal_waves_spells]['Healing Wave'][:buffed].to_i + self.kpi_hash[:tidal_waves_spells]['Healing Surge'][:buffed].to_i rescue 0
    self.resources_hash[:vigor_uptime] = @uptimes['Ancestral Vigor'][:uptime]
    self.kpi_hash[:chain_heal_hits][@chain_heal_hits] = self.kpi_hash[:chain_heal_hits][@chain_heal_hits].to_i + 1
    self.kpi_hash[:chain_heal_good] = self.kpi_hash[:chain_heal_hits][4].to_i + self.kpi_hash[:chain_heal_hits][5].to_i + self.kpi_hash[:chain_heal_hits][6].to_i
    self.kpi_hash[:chain_heal_total] = self.kpi_hash[:chain_heal_hits].map{|k,v| v }.sum rescue 0
    self.cooldowns_hash[:ascendance_healing] = @kpis['Ascendance'].map{|kpi| kpi[:healing_increase].to_i }.sum rescue 0
    self.cooldowns_hash[:ascendance_overhealing] = @kpis['Ascendance'].map{|kpi| kpi[:overhealing_increase].to_i }.sum rescue 0
    self.cooldowns_hash[:guidance_healing] = @kpis['Ancestral Guidance'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:guidance_overhealing] = @kpis['Ancestral Guidance'].map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:queen_healing] = @kpis['Gift of the Queen'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:queen_overhealing] = @kpis['Gift of the Queen'].map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
  end

end