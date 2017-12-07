class FightParse::Demonhunter::Havoc < FightParse
  include Filterable
  self.table_name = :fp_dh_havoc

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 8
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      casts_score: 0,
      momentum_score: 0,
      momentum_casts: {},
      momentum_count: 0,
      early_momentum_count: 0,
      early_momentum_casts: [],
      fury_good_gain: 0,
      fury_bad_gain: 0,
      fury_bad_gain_casts: [],
      fury_good_spend: 0,
      fury_bad_spend: 0,
      fury_bad_spend_casts: [],
      blade_dance: 0,
      bad_blade_dance: 0,
      eyebeam_ticks: 0,
      eyebeam_multiple: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      momentum_uptime: 0,
      momentum_up_fury: 0,
      momentum_down_fury: 0,
      fury_gain: 0,
      fury_waste: 0,
      fury_abilities: {},
    }
    self.cooldowns_hash = {
      illidari_damage: 0,
      illidari_extra_damage: 0,
      metamorphosis_damage: 0,
      eyebeam_damage: 0,
      eyebeam_extra_damage: 0,
      chaosblades_damage: 0,
      felbarrage_damage: 0,
    }
    @resources = {
      "r#{ResourceType::FURY}" => 0,
      "r#{ResourceType::FURY}_max" => self.max_fury,
    }
    @fury = 0
    @max_fury = 0
    @early_momentum = 0
    @last_felrush_tick = 0
    @bladedance_enemies = []
    @eyebeam_time = 0
    @eyebeam_ticks = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      162243 => 'Demon\'s Bite',
      162794 => 'Chaos Strike',
      195072 => 'Fel Rush',
      192611 => 'Fel Rush',
      192939 => 'Fel Mastery',
      198793 => 'Vengeful Retreat',
      203551 => 'Prepared',
      198013 => 'Eye Beam',
      200166 => 'Metamorphosis',
      191427 => 'Metamorphosis',
      162264 => 'Metamorphosis',
      185123 => 'Throw Glaive',
      213241 => 'Felblade',
      206416 => 'First Blood',
      206473 => 'Bloodlet',
      206476 => 'Momentum',
      208628 => 'Momentum',
      211881 => 'Fel Eruption',
      206491 => 'Nemesis',
      203556 => 'Master of the Glaive',
      211048 => 'Chaos Blades',
      211796 => 'Chaos Blades',
      211797 => 'Chaos Blades',
      211052 => 'Fel Barrage',
      211053 => 'Fel Barrage',
      222707 => 'Fel Barrage',
      201467 => 'Fury of the Illidari',
      201789 => 'Fury of the Illidari',
      201469 => 'Demon Speed',
      203555 => 'Demon Blades',
      188499 => 'Blade Dance',
      210152 => 'Death Sweep',
      198589 => 'Blur',
      212800 => 'Blur',
      201454 => 'Contained Fury',
      202446 => 'Anguish',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Metamorphosis'] = {cd: 300}
    local['Fury of the Illidari'] = {cd: 60}
    local['Blur'] = {cd: 60} if talent(4) == 'Momentum'
    # local['Eye Beam'] = {cd: 45}
    local['Fel Eruption'] = {cd: 35} if talent(4) == 'Fel Eruption'
    # local['Fel Barrage'] = {cd: 30} if talent(6) == 'Fel Barrage'
    if talent(1) == 'Prepared' 
      local['Vengeful Retreat'] = {cd: 15} 
    elsif talent(4) == 'Momentum'
      local['Vengeful Retreat'] = {cd: 25} 
    end
    local['Felblade'] = {cd: 15} if talent(2) == 'Felblade'
    local['Fel Rush'] = {cd: 10, extra: 1} if talent(4) == 'Momentum'
    local['Blade Dance'] = {cd: (10 * self.haste_reduction_ratio)} if talent(2) == 'First Blood'
    # local['Throw Glaive'] = {cd: (10 * self.haste_reduction_ratio)} if talent(2) == 'Bloodlet'
    # local['Throw Glaive'] = {cd: (10 * self.haste_reduction_ratio), extra: 1} if talent(5) == 'Master of the Glaive'
    
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Chaos Blades'] = {cd: 300}
    bars['cd']['Metamorphosis'] = {cd: 300}
    bars['cd']['Fury of the Illidari'] = {cd: 60}
    bars['cd']['Fel Barrage'] = {} if talent(6) == 'Fel Barrage'
    bars['cd']['Eye Beam'] = {cd: 45}
    
    return bars
  end

  def cooldown_abilities
    local = {
      'Metamorphosis' => {kpi_hash: {damage_done: 0}},
      'Eye Beam' => {kpi_hash: {damage_done: 0}},
      'Fel Barrage' => {kpi_hash: {charges: 0, damage_done: 0}},
      'Fury of the Illidari' => {kpi_hash: {damage_done: 0, extra_damage: 0}},
      'Chaos Blades' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Momentum' => {},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Metamorphosis' => {},
      'Chaos Blades' => {percent: 0.3, ignore: ['Chaos Blades']},
      # 'Nemesis' => {percent: 0.2},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Eye Beam' => {channel: true},
      'Anguish' => {piggyback: 'Eye Beam'},
      'Fel Barrage' => {},
      'Fury of the Illidari' => {},
      'Rage of the Illidari' => {piggyback: 'Fury of the Illidari'},
    }
    return super.merge local
  end

  def max_fury
    return 100 + 10 * artifact('Contained Fury')
  end

  def fel_mastery_gain
    return 25
  end

  def max_momentum
    max = (talent(1) == 'Prepared' ? 65 : 57)
    max += 8 if artifact('Demon Speed')
    return max
  end

  def track_resources
    return [ResourceType::FURY]
  end

  # getters

  def mastery_percent
    return 8 + super
  end

  def momentum_cast_bars
    arr = []
    return arr if self.kpi_hash[:momentum_casts].nil?
    if talent(6) == 'Fel Barrage'
      arr << {name: 'Fel Barrage', good: self.kpi_hash[:momentum_casts]['Fel Barrage (ticks)'].to_i, total: (self.kpi_hash[:momentum_casts]['Fel Barrage (ticks)'].to_i + self.kpi_hash[:momentum_casts]['Fel Barrage (bad)'].to_i)}
    end
    arr << {name: 'Fury of the Illidari', good: self.kpi_hash[:momentum_casts]['Fury of the Illidari (ticks)'].to_i, total: (self.kpi_hash[:momentum_casts]['Fury of the Illidari (ticks)'].to_i + self.kpi_hash[:momentum_casts]['Fury of the Illidari (bad)'].to_i)}
    # arr << {name: 'Eye Beam', good: self.kpi_hash[:momentum_casts]['Eye Beam (ticks)'].to_i, total: (self.kpi_hash[:momentum_casts]['Eye Beam (ticks)'].to_i + self.kpi_hash[:momentum_casts]['Eye Beam (bad)'].to_i)},
    if talent(2) == 'Bloodlet'
      arr << {name: 'Throw Glaive', good: self.kpi_hash[:momentum_casts]['Throw Glaive'].to_i, total: (self.casts_hash['Throw Glaive'].count rescue 0)}
    end
    return arr
  end

  # event handlers

  def cast_event(event)
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    @casts_details.pop if ability_name == 'Vengeful Retreat' && @casts_details.count > 0 && @casts_details.last['ability'] == 'Fel Rush'
    super
    
    if @uptimes['Momentum'][:active]
      self.kpi_hash[:momentum_casts][ability_name] = self.kpi_hash[:momentum_casts][ability_name].to_i + 1 
    end
    if ability_name == 'Vengeful Retreat'
      # We assumed a Fel Rush gave Momentum, so get rid of that
      self.casts_hash['Fel Rush'].delete(event['timestamp']) if self.casts_hash.has_key?('Fel Rush')
      if self.kpi_hash[:early_momentum_casts].count > 0 && self.kpi_hash[:early_momentum_casts].last[:timestamp] == event['timestamp']
        self.kpi_hash[:early_momentum_casts].last[:msg] = "Refreshed Momentum early with Vengeful Retreat"
      end
    elsif ability_name == 'Chaos Strike'
      if @max_fury - @fury >= 30 && !@uptimes['Momentum'][:active]
        self.kpi_hash[:fury_bad_spend] += 1
        self.kpi_hash[:fury_bad_spend_casts] << {timestamp: event['timestamp'], msg: "Cast Chaos Strike with no Momentum and #{@fury} Fury"}
      else
        self.kpi_hash[:fury_good_spend] += 1
      end
    elsif ability_name == 'Blade Dance' || ability_name == 'Death Sweep'
      if ability_name == 'Death Sweep' && talent(2) == 'First Blood'
        # this casts counts as Blade Dance
        self.casts_hash['Blade Dance'] << event['timestamp']
        @casts_details.pop if @casts_details.last['ability'] == 'Death Sweep'
        save_cast_detail(event, 'Blade Dance', 'cast', "Cast Death Sweep")
        @cds.delete('Death Sweep')
        @cds['Blade Dance'] = (event['timestamp'] + self.track_casts['Blade Dance'][:cd] * 1000).to_i
      end
      self.kpi_hash[:blade_dance] += 1
      self.kpi_hash[:bad_blade_dance] += 1
      @bladedance_enemies = []
    end
      
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::FURY
        @fury = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        @max_fury = resource['max'].to_i
        if @uptimes['Momentum'][:active]
          self.resources_hash[:momentum_up_fury] += resource['cost'].to_i
        else
          self.resources_hash[:momentum_down_fury] += resource['cost'].to_i
        end
      end
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"

    if ability_name == 'Fury of the Illidari'
      key = @uptimes['Momentum'][:active] ? 'Fury of the Illidari (ticks)' : 'Fury of the Illidari (bad)'
      self.kpi_hash[:momentum_casts][key] = self.kpi_hash[:momentum_casts][key].to_i + 1
    elsif ability_name == 'Fel Barrage'
      key = @uptimes['Momentum'][:active] ? 'Fel Barrage (ticks)' : 'Fel Barrage (bad)'
      self.kpi_hash[:momentum_casts][key] = self.kpi_hash[:momentum_casts][key].to_i + 1
    elsif ability_name == 'Eye Beam'
      key = @uptimes['Momentum'][:active] ? 'Eye Beam (ticks)' : 'Eye Beam (bad)'
      self.kpi_hash[:momentum_casts][key] = self.kpi_hash[:momentum_casts][key].to_i + 1
      # see how many ticks hit multiple targets
      if @eyebeam_time == event['timestamp']
        @eyebeam_ticks += 1
        self.kpi_hash[:eyebeam_multiple] += 1 if @eyebeam_ticks == 2
      else
        self.kpi_hash[:eyebeam_ticks] += 1
        @eyebeam_time = event['timestamp']
        @eyebeam_ticks = 1
      end
    elsif ability_name == 'Fel Rush'
      if @early_momentum > 0 && @last_felrush_tick == @early_momentum
        # Fel Rush refreshed momentum but hit multiple mobs
        self.kpi_hash[:early_momentum_count] -= 1
        self.kpi_hash[:early_momentum_casts].pop
        self.kpi_hash[:early_momentum_casts] << {timestamp: event['timestamp'], class: 'green', msg: "Refreshed Momentum early with Fel Rush, but hit multiple targets"}
        @early_momentum = 0
      end
      if @last_felrush_tick != event['timestamp'] && talent(0) == 'Fel Mastery'
        # this is the first tick with this timestamp
        # gain_fury('Fel Mastery', self.fel_mastery_gain, event['timestamp'])
      end
      @last_felrush_tick = event['timestamp']
    elsif ability_name == 'Chaos Blades'
      unless @cooldowns['Chaos Blades'][:cp].nil?
        @cooldowns['Chaos Blades'][:cp].kpi_hash[:damage_done] += event['amount'].to_i
        @cooldowns['Chaos Blades'][:cp].details_hash[event['ability']['guid']] ||= {name: ability_name, damage: 0, hits: 0}
        @cooldowns['Chaos Blades'][:cp].details_hash[event['ability']['guid']][:damage] += event['amount'].to_i
        @cooldowns['Chaos Blades'][:cp].details_hash[event['ability']['guid']][:hits] += 1
      end
    elsif ability_name == 'Blade Dance' || ability_name == 'Death Sweep'
      unless @bladedance_enemies.nil?
        @bladedance_enemies = (@bladedance_enemies << target_key).uniq
        if @bladedance_enemies.size > 1
          self.kpi_hash[:bad_blade_dance] -= 1
          @bladedance_enemies = nil
        end
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Momentum'
      self.kpi_hash[:momentum_count] += 1
      #assume Fel Rush initially, change later if it was Vengeful Retreat
      self.casts_hash['Fel Rush'] ||= []
      self.casts_hash['Fel Rush'] << event['timestamp']
      save_cast_detail(event, 'Fel Rush', 'cast')
      # get rid of old clipping flags
      @early_momentum = 0  if @early_momentum != event['timestamp']
      @last_felrush_tick = 0
    elsif ability_name == 'Blur'
      self.casts_hash['Blur'] ||= []
      self.casts_hash['Blur'] << event['timestamp']
    end
  end

  def refresh_self_buff_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Momentum'
      @early_momentum = event['timestamp']
      self.kpi_hash[:early_momentum_count] += 1 
      self.kpi_hash[:early_momentum_casts] << {timestamp: event['timestamp'], class: 'red', msg: "Refreshed Momentum early with Fel Rush"}
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Demon\'s Bite'
      if @fury >= 40 && @uptimes['Momentum'][:active]
        self.kpi_hash[:fury_bad_gain] += 1
        self.kpi_hash[:fury_bad_gain_casts] << {timestamp: event['timestamp'], msg: "Cast Demon's Bite with Momentum and #{@fury} Fury"}
      else
        self.kpi_hash[:fury_good_gain] += 1
      end
    end
    if event['resourceChangeType'] == ResourceType::FURY
      gain_fury(ability_name, event['resourceChange'].to_i, event['timestamp'])
    end
  end

  def gain_fury(ability_name, gain, timestamp)
    fury_waste = [@fury + gain - @max_fury, 0].max
    fury_gain = gain - fury_waste
    @fury += fury_gain
    if ability_name == 'Fel Mastery'
    end
    self.resources_hash[:fury_gain] += fury_gain
    self.resources_hash[:fury_waste] += fury_waste
    self.resources_hash[:fury_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
    self.resources_hash[:fury_abilities][ability_name][:gain] += fury_gain
    self.resources_hash[:fury_abilities][ability_name][:waste] += fury_waste
  end

  def clean
    super
    momentum_score_max =  (self.casts_hash['Throw Glaive'].count rescue 0) + self.kpi_hash[:momentum_casts]['Fury of the Illidari (ticks)'].to_i + self.kpi_hash[:momentum_casts]['Fury of the Illidari (bad)'].to_i + self.kpi_hash[:momentum_casts]['Fel Barrage (ticks)'].to_i + self.kpi_hash[:momentum_casts]['Fel Barrage (bad)'].to_i
    momentum_score = [self.kpi_hash[:momentum_casts]['Throw Glaive'].to_i + self.kpi_hash[:momentum_casts]['Fury of the Illidari (ticks)'].to_i + self.kpi_hash[:momentum_casts]['Fel Barrage (ticks)'].to_i, momentum_score_max].min
    self.kpi_hash[:momentum_score] = 100 * momentum_score / momentum_score_max rescue 0
    self.resources_hash[:momentum_uptime] = @uptimes['Momentum'][:uptime].to_i
    self.cooldowns_hash[:eyebeam_damage] = @kpis['Eye Beam'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:eyebeam_extra_damage] = @kpis['Eye Beam'].map{|kpi| kpi[:extra_damage]}.sum rescue 0
    self.cooldowns_hash[:metamorphosis_damage] = @kpis['Metamorphosis'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:illidari_damage] = @kpis['Fury of the Illidari'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:illidari_extra_damage] = @kpis['Fury of the Illidari'].map{|kpi| kpi[:extra_damage]}.sum rescue 0
    self.cooldowns_hash[:chaosblades_damage] = @kpis['Chaos Blades'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:felbarrage_damage] = @kpis['Fel Barrage'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldown_parses.where(name: 'Fel Barrage').each do |cp|
      cp.destroy if cp.started_at == cp.ended_at && cp.kpi_hash[:damage_done] == 0
    end
    self.save
  end

end