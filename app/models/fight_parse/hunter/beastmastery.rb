class FightParse::Hunter::Beastmastery < FightParse
  include Filterable
  self.table_name = :fp_hunter_beast

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end
  
  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      wildcall_procs: 0,
      wildcall_wasted: 0,
      wildcall_waste_details: [],
      direbeast_reduction: 0,
      thunder_with_dire: 0,
      thunder_without_dire: 0,
      thunder_fail_details: [],
    }
    self.resources_hash = {
      capped_time: 0,
      focus_gain: 0,
      focus_waste: 0,
      focus_abilities: {},
      focus_damage: 0,
      focus_spent: 0,
      focus_spend: {},
    }
    self.cooldowns_hash = {
      bestial_cobra: 0,
    }
    @resources = {
      "r#{ResourceType::FOCUS}" => 0,
      "r#{ResourceType::FOCUS}_max" => self.max_focus,
    }
    @focus = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      19574 => 'Bestial Wrath',
      120679 => 'Dire Beast',
      120694 => 'Dire Beast',
      34026 => 'Kill Command',
      83381 => 'Kill Command',
      197163 => 'Jaws of Thunder',
      193455 => 'Cobra Shot',
      193530 => 'Aspect of the Wild',
      207068 => 'Titan\'s Thunder',
      207097 => 'Titan\'s Thunder',
      201430 => 'Stampede',
      201594 => 'Stampede',
      131894 => 'A Murder of Crows',
      131900 => 'A Murder of Crows',
      217200 => 'Dire Frenzy',
      120360 => 'Barrage',
      120361 => 'Barrage',
      185791 => 'Wild Call',
      199532 => 'Killer Cobra',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Stampede'] = {cd: 180} if talent(6) == 'Stampede'
    local['Aspect of the Wild'] = {cd: 120}
    local['Bestial Wrath'] = {cd: 90, reduction: self.kpi_hash[:direbeast_reduction].to_i}
    local['Titan\'s Thunder'] = {cd: 60}
    local['A Murder of Crows'] = {cd: 60} if talent(5) == 'A Murder of Crows'
    local['Barrage'] = {cd: 20} if talent(5) == 'Barrage'
    if talent(1) == 'Dire Frenzy'
      local['Dire Frenzy'] = {cd: 12 * self.haste_reduction_ratio, extra: 1}
    else
      local['Dire Beast'] = {cd: 12 * self.haste_reduction_ratio, extra: 1 + self.kpi_hash[:wildcall_procs].to_i}
    end
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Stampede'] = {cd: 180} if talent(6) == 'Stampede'
    bars['cd']['Aspect of the Wild'] = {cd: 120}
    bars['cd']['Bestial Wrath'] = {cd: 90, reduction: self.kpi_hash[:direbeast_reduction].to_i}
    bars['cd']['Titan\'s Thunder'] = {cd: 60}
    bars['cd']['A Murder of Crows'] = {cd: 60} if talent(5) == 'A Murder of Crows'
    bars['cd']['Barrage'] = {cd: 20} if talent(5) == 'Barrage'
    return bars
  end

  def uptime_abilities
    local = {
      'Wild Call' => {},
      'Killer Cobra' => {},
      'Dire Beast' => {},
      'Dire Frenzy' => {},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Bestial Wrath' => {kpi_hash: {damage_done: 0, killercobra: 0, killcommand: 0}},
      'Aspect of the Wild' => {kpi_hash: {damage_done: 0}},
      'Titan\'s Thunder' => {kpi_hash: {damage_done: 0}},
      'Stampede' => {kpi_hash: {damage_done: 0}},
      'A Murder of Crows' => {kpi_hash: {damage_done: 0}},
      'Barrage' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Barrage' => {channel: true},
      'Titan\'s Thunder' => {},
      'Stampede' => {},
      'A Murder of Crows' => {},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Bestial Wrath' => {},
      'Aspect of the Wild' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::FOCUS]
  end

  # getters

  def max_focus
    return 120
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Dire Beast' || ability_name == 'Dire Frenzy'
      self.kpi_hash[:direbeast_reduction] += 12
    elsif ability_name == 'Titan\'s Thunder'
      if @uptimes['Dire Beast'][:active] || @uptimes['Dire Frenzy'][:active]
        self.kpi_hash[:thunder_with_dire] += 1 
      else
        self.kpi_hash[:thunder_without_dire] += 1 
        self.kpi_hash[:thunder_fail_details] << {timestamp: event['timestamp'], msg: "Cast Titan's Thunder without Dire Beast"}
      end
    end
    if @cooldowns['Bestial Wrath'][:active] && !@cooldowns['Bestial Wrath'][:temp]
      if ability_name == 'Cobra Shot' 
        @cooldowns['Bestial Wrath'][:cp].kpi_hash[:killercobra] += 1
      elsif ability_name == 'Kill Command'
        @cooldowns['Bestial Wrath'][:cp].kpi_hash[:killcommand] += 1
      end
    end

    ability_name ||= event['ability']['name']
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::FOCUS
        @focus = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
        if resource['cost'].to_i > 0
          self.resources_hash[:focus_spend][ability_name] ||= {name: ability_name, spent: 0, damage: 0}
          self.resources_hash[:focus_spend][ability_name][:spent] += resource['cost'].to_i
        end
      end
    end
  end

  def refresh_self_buff_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.kpi_hash[:wildcall_wasted] += 1 if ability_name == 'Wild Call'
    self.kpi_hash[:wildcall_waste_details] << {timestamp: event['timestamp'], msg: "Overwrote Wild Call"}
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.kpi_hash[:wildcall_procs] += 1 if ability_name == 'Wild Call'
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::FOCUS
      focus_waste = [@focus + event['resourceChange'].to_i - self.max_focus, 0].max
      focus_gain = event['resourceChange'].to_i - focus_waste
      @focus += focus_gain
      self.resources_hash[:focus_gain] += focus_gain
      self.resources_hash[:focus_waste] += focus_waste
      self.resources_hash[:focus_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:focus_abilities][ability_name][:gain] += focus_gain
      self.resources_hash[:focus_abilities][ability_name][:waste] += focus_waste
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    ability_name = 'Kill Command' if ability_name == 'Jaws of Thunder'
    if self.resources_hash[:focus_spend].has_key?(ability_name)
      self.resources_hash[:focus_spend][ability_name][:damage] += event['amount'].to_i
    end
  end

  def pet_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if @pets.has_key?(event['sourceID']) && @pets[event['sourceID']][:stampede]
      target_key = "#{target_id}-#{event['targetInstance']}"
      @cooldowns['Stampede'][:cp].kpi_hash[:damage_done] += event['amount']
      @cooldowns['Stampede'][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns['Stampede'][:cp].details_hash[target_key][:damage] += event['amount']
      @cooldowns['Stampede'][:cp].details_hash[target_key][:hits] += 1
    end
    ability_name = 'Kill Command' if ability_name == 'Jaws of Thunder'
    if self.resources_hash[:focus_spend].has_key?(ability_name)
      self.resources_hash[:focus_spend][ability_name][:damage] += event['amount'].to_i
    end
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if ability_name == 'Stampede'
      @pets[target_id][:stampede] = true
    end
  end

  def clean
    super
    self.cooldown_parses.where('started_at = ended_at').destroy_all
    focus_regen = (self.fight_time * (10 / self.haste_reduction_ratio)).to_i
    regen_wasted = (self.resources_hash[:capped_time].to_i * (10 / self.haste_reduction_ratio)).to_i
    self.resources_hash[:focus_gain] += focus_regen
    self.resources_hash[:focus_waste] += regen_wasted
    self.resources_hash[:focus_abilities]['Passive Gain'] = {name: 'Passive Gain', gain: focus_regen - regen_wasted, waste: regen_wasted}
    self.resources_hash[:focus_spend].each do |key, spell|
      self.resources_hash[:focus_damage] += spell[:damage].to_i
      self.resources_hash[:focus_spent] += spell[:spent].to_i
    end
    self.cooldowns_hash[:bestial_cobra] = @kpis['Bestial Wrath'].map{|kpi| kpi[:killercobra].to_i}.sum rescue 0
    self.cooldowns_hash[:bestial_kill] = @kpis['Bestial Wrath'].map{|kpi| kpi[:killcommand].to_i}.sum rescue 0
    aggregate_dps_cooldowns
    self.save
  end

end