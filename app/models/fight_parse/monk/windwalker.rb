class FightParse::Monk::Windwalker < FightParse
  include Filterable
  self.table_name = :fp_monk_wind

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 9
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
      mastery: {success: 0, fail: 0, fail_details: []},
      pressure_point_gained: 0,
      pressure_point_used: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      chi_gain: 0,
      chi_waste: 0,
      chi_abilities: {},
    }
    self.cooldowns_hash = {
      fof_damage: 0,
      fof_cdr: 0,
      stw_damage: 0,
      serenity_damage: 0,
      serenity_cdr: 0,
      tod_damage: 0,
      tod_extra_damage: 0,
      sck_damage: 0,
      xuen_damage: 0,
      sef_damage: 0,
      sef_extra_damage: 0,
    }
    @mark_of_crane = []
    @recent_casts = []
    @sef_ids = []
    @resources = {
      "r#{ResourceType::CHI}" => 0,
      "r#{ResourceType::CHI}_max" => self.max_chi,
    }
    @chi = 0
    self.save
  end

  # settings

  def track_casts
    local = {}
    local['Touch of Death'] = {cd: 120}
    if talent(6) == 'Serenity'
      local['Serenity'] = {cd: 90} 
    else
      local['Storm, Earth, and Fire'] = {cd: 90, extra: 1}
    end
    local['Energizing Elixir'] = {cd: 60} if talent(2) == 'Energizing Elixir'
    local['Strike of the Windlord'] = {cd: 40}
    local['Fists of Fury'] = {cd: (24 * self.haste_reduction_ratio), reduction: self.cooldowns_hash[:fof_cdr].to_i}
    if talent(6) == 'Whirling Dragon Punch'
      local['Whirling Dragon Punch'] = {cd: (24 * self.haste_reduction_ratio)}
    end
    local['Rising Sun Kick'] = {cd: ((self.set_bonus(19) >= 2 ? 7 : 10) * self.haste_reduction_ratio)}
    local['Chi Burst'] = {cd: 30} if talent(0) == 'Chi Burst'
    # local['Chi Wave'] = {cd: 15, no_score: true} if talent(0) == 'Chi Wave'
      
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['pet']['Xuen'] = {cd: 180} if talent(5) == 'Invoke Xuen, the White Tiger'
    bars['cd']['Touch of Death'] = {cd: 120}
    bars['cd']['Serenity'] = {cd: 90 - split_personality_reduction} if talent(6) == 'Serenity'
    bars['cd']['Storm, Earth, and Fire'] = {cd: 90 - split_personality_reduction, extra: 1} if talent(6) != 'Serenity'
    bars['cd']['Fists of Fury'] = {cd: (24 * self.haste_reduction_ratio)}
    bars['cd']['Strike of the Windlord'] = {cd: 40}
        
    return bars
  end

  def cooldown_abilities
    local = {
      'Fists of Fury' => {kpi_hash: {damage_done: 0, hits: 0}},
      'Strike of the Windlord' => {kpi_hash: {damage_done: 0}},
      'Spinning Crane Kick' => {kpi_hash: {damage_done: 0, stacks: 0}},
      'Serenity' => {kpi_hash: {damage_done: 0, cdr_gain: 0, cdr_details: []}},
      'Storm, Earth, and Fire' => {kpi_hash: {damage_done: 0}},
      'Touch of Death' => {kpi_hash: {damage_done: 0, extra_damage: 0}},
    }
    return super.merge local
  end

  def uptime_abilities
    local = {
      'Pressure Point' => {},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Hit Combo' => {target_stacks: 6},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Serenity' => {percent: 0.4},
      'Storm, Earth, and Fire' => {},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Fists of Fury' => {channel: true},
      'Strike of the Windlord' => {},
      'Crosswinds' => {piggyback: 'Fists of Fury'},
      'Spinning Crane Kick' => {channel: true},
      'Touch of Death' => {single: true},
    }
    return super.merge local
  end

  def max_chi
    talent(2) == 'Ascension' ? 6 : 5
  end

  def track_resources
    return [ResourceType::CHI]
  end

  def show_resources
    return [ResourceType::CHI, ResourceType::ENERGY]
  end

  def fof_headers
    if talent(6) != 'Serenity'
      headers = ['Enemy', 'Source', 'Damage', 'Hits']
    else
      headers = ['Enemy', 'Damage', 'Hits']
    end
    # headers << 'Clone 2' if talent(6) != 'Serenity'
    headers << 'Crosswinds' if artifact('Crosswinds')
    return headers
  end

  def fof_values(details_hash)
    values = []
    puts details_hash
    details_hash.values.each do |hash|
      if talent(6) != 'Serenity'
        row = [hash[:name], (hash[:source] || self.player_name), hash[:damage].to_i + hash[:extra_damage].to_i, hash[:hits].to_i]
      else
        row = [hash[:name], hash[:damage].to_i + hash[:extra_damage].to_i, hash[:hits].to_i]
      end
      row << hash[:extra_hits].to_i if artifact('Crosswinds')
      values << row
      puts row
    end
    puts values
    return values
  end

  def fof_hits_s(values)
    hits = values.map{|mob| mob[:hits].to_i}.max.to_i
    if hits >= 5
      return "#{hits} hits"
    else
      return "<span class='red'>#{hits} hits</span>"
    end
  end

  def split_personality_reduction
    case artifact('Split Personality').to_i
    when 1
      return 5
    when 2
      return 10
    when 3
      return 15
    when 4
      return 20
    when 5
      return 24
    when 6
      return 28
    when 7
      return 31
    when 8
      return 34
    else
      return 0
    end
  end

  # getters

  SET_IDS = {
    19 => [138325, 138328, 138331, 138334, 138337, 138367],
    20 => [147151, 147152, 147153, 147154, 147155, 147156],
  }

  def spell_name(id)
    return {
      6603   => 'Melee',
      100780 => 'Tiger Palm',
      100784 => 'Blackout Kick',
      113656 => 'Fists of Fury',
      117418 => 'Fists of Fury',
      196061 => 'Crosswinds',
      152173 => 'Serenity',
      115080 => 'Touch of Death',
      229980 => 'Touch of Death',
      107428 => 'Rising Sun Kick',
      152175 => 'Whirling Dragon Punch',
      123986 => 'Chi Burst',
      115098 => 'Chi Wave',
      196741 => 'Hit Combo',
      101546 => 'Spinning Crane Kick',
      107270 => 'Spinning Crane Kick',
      137639 => 'Storm, Earth, and Fire',
      138121 => 'Storm, Earth, and Fire',
      138123 => 'Storm, Earth, and Fire',
      228287 => 'Mark of the Crane',
      117952 => 'Crackling Jade Lightning',
      101545 => 'Flying Serpent Kick',
      116847 => 'Rushing Jade Wind',
      115396 => 'Ascension',
      115288 => 'Energizing Elixir',
      123904 => 'Invoke Xuen, the White Tiger',
      195399 => 'Gale Burst',
      205320 => 'Strike of the Windlord',
      222029 => 'Strike of the Windlord',
      205414 => 'Strike of the Windlord',
      238059 => 'Split Personality',
      247255 => 'Pressure Point',
    }[id] || super(id)
  end

  def ticks
    local = {
      117418 => 'Fists of Fury',
    }
    return super.merge local
  end

  def hitcombo_abilities
    return [
      'Blackout Kick',
      'Crackling Jade Lightning',
      'Fists of Fury',
      'Flying Serpent Kick',
      'Rising Sun Kick',
      'Spinning Crane Kick',
      'Strike of the Windlord',
      'Tiger Palm',
      'Touch of Death',
      'Chi Wave',
      'Chi Burst',
      'Rushing Jade Wind',
      'Whirling Dragon Punch',
    ]
  end

  def pet_name(id)
    return {
      63508 => 'Xuen',
    }[id]
  end

  def max_cooldown
    return [self.cooldowns_hash[:fof_damage], self.cooldowns_hash[:serenity_damage], self.cooldowns_hash[:tod_damage], self.cooldowns_hash[:sck_damage], self.cooldowns_hash[:xuen_damage]].max
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id}-#{event['targetInstance']}"
    return if ability_name.nil?
    if hitcombo_abilities.include?(ability_name)
      @recent_casts.push({timestamp: event['timestamp'], ability: ability_name})
      @recent_casts.shift if @recent_casts.size > 4
      if @recent_casts.size <= 1 || @recent_casts[-1][:ability] != @recent_casts[-2][:ability]
        self.kpi_hash[:mastery][:success] += 1
      elsif ability_name != 'Spinning Crane Kick' # ignore 2 SCK in a row, since ticks have the same spell ID
        self.kpi_hash[:mastery][:fail] += 1
        self.kpi_hash[:mastery][:fail_details] << Array.new(@recent_casts)
      end
    end
    if ability_name == 'Fists of Fury'
      @cooldowns['Fists of Fury'][:cp].kpi_hash[:hits] += 1
    elsif ability_name == 'Rising Sun Kick' && @uptimes['Pressure Point'][:active]
      self.kpi_hash[:pressure_point_used] += 1
    elsif ability_name == 'Spinning Crane Kick'
      @cooldowns['Spinning Crane Kick'][:cp].kpi_hash[:stacks] = @mark_of_crane.size
    elsif ability_name == 'Touch of Death'
      @cooldowns['Touch of Death'][:target_key] = target_key
    end
    # if @cooldowns['Serenity'][:active] && ['Fists of Fury', 'Strike of the Windlord', 'Rising Sun Kick'].include?(ability_name)
      # cdr_gain = (self.track_casts[ability_name][:cd] * 0.5).round(1)
      # @cooldowns['Serenity'][:cp].kpi_hash[:cdr_gain] += cdr_gain
      # @cooldowns['Serenity'][:cp].kpi_hash[:cdr_details] << {timestamp: event_time(event['timestamp'], true, @cooldowns['Serenity'][:cp].started_at), ability: ability_name, cdr: "#{cdr_gain}s"}
    # end
    (event['classResources'] || []).each do |resource|
      check_resource_cap(resource['amount'], resource['max'], event['timestamp']) if resource['type'] == ResourceType::ENERGY
      @chi = [resource['amount'].to_i - resource['cost'].to_i, 0].max if resource['type'] == ResourceType::CHI
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id}-#{event['targetInstance']}"
    # gale burst
    if artifact('Gale Burst') >= 1 && @cooldowns['Touch of Death'][:active] && @cooldowns['Touch of Death'][:target_key] == target_key && ability_name != 'Touch of Death'
      @cooldowns['Touch of Death'][:cp].kpi_hash[:extra_damage] += event['amount'] / 10
      @cooldowns['Touch of Death'][:cp].details_hash[ability_name] ||= {name: ability_name, extra_damage: 0, hits: 0}
      @cooldowns['Touch of Death'][:cp].details_hash[ability_name][:extra_damage] += event['amount']
      @cooldowns['Touch of Death'][:cp].details_hash[ability_name][:hits] += 1
    end
    #t20 bonus
    if ability_name == 'Rising Sun Kick' && event['hitType'] == 2 && self.set_bonus(20) >= 2
      self.cooldowns_hash[:fof_cdr] += 3
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::CHI
      if ability_name == 'Energizing Elixir'
        # special code because waste isn't calculated by default
        chi_waste = @chi
        chi_gain = self.max_chi - @chi
        @chi = self.max_chi
        @energize[ability_name] ||= {}
        @energize[ability_name]["r#{event['resourceChangeType']}"] = chi_gain
      else
        chi_waste = [@chi + event['resourceChange'].to_i - self.max_chi, 0].max
        chi_gain = event['resourceChange'].to_i - chi_waste
        @chi += chi_gain
      end
      self.resources_hash[:chi_gain] += chi_gain
      self.resources_hash[:chi_waste] += chi_waste
      self.resources_hash[:chi_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:chi_abilities][ability_name][:gain] += chi_gain
      self.resources_hash[:chi_abilities][ability_name][:waste] += chi_waste
      
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Pressure Point'
      self.kpi_hash[:pressure_point_gained] += 1
    end
  end

  def lose_self_buff_event(event, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Storm, Earth, and Fire'
      @sef_ids.each{|id| pet_death(id, event['timestamp'])}
      @sef_ids = []
    end
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Storm, Earth, and Fire'
      event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
      @sef_ids << target_id
    end
  end

  def pet_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if self.dps_abilities.has_key?(ability_name)
      @cooldowns[ability_name][:cp].kpi_hash[:extra_damage] = @cooldowns[ability_name][:cp].kpi_hash[:extra_damage].to_i + event['amount'].to_i
      @cooldowns[ability_name][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0, extra_damage: 0}
      @cooldowns[ability_name][:cp].details_hash[target_key][:extra_damage] = @cooldowns[ability_name][:cp].details_hash[target_key][:extra_damage].to_i + event['amount'].to_i
      @cooldowns[ability_name][:cp].details_hash[target_key][:extra_hits] = @cooldowns[ability_name][:cp].details_hash[target_key][:extra_hits].to_i + 1
      # source_key = "#{@actors[event['sourceID']]}_hits"
      # @cooldowns[ability_name][:cp].details_hash[target_key][source_key] = @cooldowns[ability_name][:cp].details_hash[target_key][source_key].to_i + 1
    end    
  end

  def apply_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if ability_name == 'Mark of the Crane'
      @mark_of_crane << target_id unless @mark_of_crane.include? target_id
    end
  end

  def remove_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if ability_name == 'Mark of the Crane'
      @mark_of_crane.delete target_id if @mark_of_crane.include? target_id
    end
  end

  def clean
    super
    @pet_kpis.each do |pet_name, kpis|
      if pet_name == 'Xuen'
        self.cooldowns_hash[:xuen_damage] = kpis.map{|kpi| kpi[:damage_done]}.sum rescue 0
        self.kpi_hash[:max_xuen] = kpis.map{|kpi| kpi[:damage_done]}.max.to_i rescue 0
      end
    end
    self.kpi_hash[:hitcombo_uptime] = @kpis['Hit Combo'].first[:stacks_uptime].to_i unless @kpis['Hit Combo'].nil?
    self.cooldowns_hash[:fof_damage] = @kpis['Fists of Fury'].map{|kpi| kpi[:damage_done].to_i + kpi[:extra_damage].to_i}.sum rescue 0
    self.cooldowns_hash[:stw_damage] = @kpis['Strike of the Windlord'].map{|kpi| kpi[:damage_done].to_i + kpi[:extra_damage].to_i}.sum rescue 0
    self.cooldowns_hash[:serenity_damage] = @kpis['Serenity'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    # self.cooldowns_hash[:serenity_cdr] = @kpis['Serenity'].map{|kpi| kpi[:cdr_gain]}.sum rescue 0
    self.cooldowns_hash[:tod_damage] = @kpis['Touch of Death'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:tod_extra_damage] = @kpis['Touch of Death'].map{|kpi| kpi[:extra_damage]}.sum rescue 0
    self.cooldowns_hash[:sck_damage] = @kpis['Spinning Crane Kick'].map{|kpi| kpi[:damage_done].to_i + kpi[:extra_damage].to_i}.sum rescue 0
    self.cooldowns_hash[:sef_damage] = @kpis['Storm, Earth, and Fire'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:sef_extra_damage] = @kpis['Storm, Earth, and Fire'].map{|kpi| kpi[:pet_damage_done].to_i}.sum rescue 0
    self.save
  end

end