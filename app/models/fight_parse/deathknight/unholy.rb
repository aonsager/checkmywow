class FightParse::Deathknight::Unholy < FightParse
  include Filterable
  self.table_name = :fp_dk_unholy

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      festering_gained: 0,
      festering_popped: 0,
      festering_capped: 0,
      festering_details: {},
      deathcoil_reductions: 0,
      soulreaper_count: 0,
      soulreaper_popped: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      vplague_uptime: 0,
      vplague_downtime: 0,
    }
    self.cooldowns_hash = {
      arbiter_damage: 0,
      transformation_damage: 0,
      apocalypse_damage: 0,
    }
    @resources = {
      "r#{ResourceType::RUNICPOWER}" => 0,
      "r#{ResourceType::RUNICPOWER}_max" => 100,
      "r#{ResourceType::RUNES}" => 0,
      "r#{ResourceType::RUNES}_max" => 6,
    }
    @battlemaiden_id = 0
    self.save
  end

  def init_pets(pets)
    pets.each do |pet_id|
      @cooldowns["Dark Transformation-#{@actors[pet_id]}"] = {active: true, temp: true, buffer: 0, cp: ExternalCooldownParse.new(fight_parse_id: self.id, target_id: pet_id, target_name: @actors[pet_id], cd_type: 'cd', name: 'Dark Transformation', kpi_hash: {damage_done: 0}, started_at: self.started_at)}
      
    end
  end

  # settings

  def spell_name(id)
    return {
      63560 => 'Dark Transformation',
      43265 => 'Death and Decay',
      207317 => 'Epidemic',
      130736 => 'Soul Reaper',
      114867 => 'Soul Reaper',
      114868 => 'Soul Reaper',
      191587 => 'Virulent Plague',
      197147 => 'Festering Wound',
      194310 => 'Festering Wound',
      55090 => 'Scourge Strike',
      85948 => 'Festering Strike',
      207349 => 'Dark Arbiter',
      211947 => 'Shadow Empowerment',
      198943 => 'Shadow Infusion',
      47541 => 'Death Coil',
      152280 => 'Defile',
      220143 => 'Apocalypse',
    }[id] || super(id)
  end

  def pet_name(id)
    return {
      27829 => 'Ebon Gargoyle',
      24207 => 'Army of the Dead',
    }[id]
  end

  def uptime_abilities
    local = {
      'Dark Transformation' => {},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Apocalypse' => {single: true},
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Virulent Plague' => {},
      'Festering Wound' => {},
      'Soul Reaper' => {},
    }
    return super.merge local
  end

  def track_casts
    local = {}
    local['Dark Arbiter'] = {cd: 120} if talent(6) == 'Dark Arbiter'
    local['Apocalypse'] = {cd: 90}
    local['Dark Transformation'] = {cd: 60}
    local['Dark Transformation'][:reduction] = self.kpi_hash[:deathcoil_reductions].to_i if talent(5) == 'Shadow Infusion'
    local['Soul Reaper'] = {cd: 45} if talent(6) == 'Soul Reaper'
    talent(6) == 'Defile' ? local['Defile'] = {cd: 30} : local['Death and Decay'] = {cd: 30, optional: true}
    local['Epidemic'] = {cd: 10, extra: 2} if talent(1) == 'Epidemic'
    
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Dark Arbiter'] = {cd: 180} if talent(6) == 'Dark Arbiter'
    bars['cd']['Apocalypse'] = {cd: 90}
    bars['external']['Dark Transformation'] = {cd: 60, reduction: self.kpi_hash[:deathcoil_reductions].to_i}
    if talent(6) == 'Defile'
      bars['external']['Defile'] = {cd: 30}
    else
      bars['cd']['Death and Decay'] = {cd: 30, optional: true}
    end
    return bars
  end


  def cooldown_abilities
    local = {
      'Dark Transformation' => {kpi_hash: {damage_done: 0}},
      'Death and Decay' => {kpi_hash: {damage_done: 0}},
      'Defile' => {kpi_hash: {damage_done: 0}},
      'Dark Arbiter' => {kpi_hash: {damage_done: 0, power_spent: 0}},
      'Apocalypse' => {kpi_hash: {damage_done: 0, wounds_popped: 0, reaper_active: false}},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::RUNICPOWER]
  end

  def show_resources
    return [ResourceType::RUNICPOWER, ResourceType::RUNES]
  end

  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Festering Strike'
      if @debuffs.has_key?('Festering Wound') && @debuffs['Festering Wound'].has_key?(target_key) && (stacks = @debuffs['Festering Wound'][target_key][:dp].stacks_array.last[:stacks]) >= 5
        # might be overcapping
        self.kpi_hash[:festering_capped] += (stacks - 4)
        self.kpi_hash[:festering_details][target_key] ||= {name: @actors[target_id], gained: 0, popped: 0, capped: 0}
        self.kpi_hash[:festering_details][target_key][:capped] += (stacks - 4)
      end
    elsif ability_name == 'Apocalypse'
      if @debuffs.has_key?('Festering Wound') && @debuffs['Festering Wound'].has_key?(target_key)
        @cooldowns['Apocalypse'][:cp].kpi_hash[:wounds_popped] = (@debuffs['Festering Wound'][target_key][:dp].stacks_array.last[:stacks].to_i rescue 0)
        @cooldowns['Apocalypse'][:cp].kpi_hash[:reaper_active] = true if (@debuffs['Soul Reaper'][target_key][:active] rescue false)
      end
    elsif ability_name == 'Death Coil' && talent(5) == 'Shadow Infusion'
      self.kpi_hash[:deathcoil_reductions] += 5 if !@uptimes['Dark Transformation'][:active]
    elsif ability_name == 'Soul Reaper'
      self.kpi_hash[:soulreaper_count] += 1
    end

    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::RUNICPOWER
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
        if is_active?("Dark Arbiter", event['timestamp'])
          @cooldowns['Dark Arbiter'][:cp].kpi_hash[:power_spent] += resource['cost'].to_i / 10
        end
      end
    end
  end

  def apply_external_buff_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if ability_name == 'Dark Transformation'
      apply_external_cooldown(ability_name, target_id, @actors[target_id], event['timestamp'], {damage_done: 0})
      gain_uptime(ability_name, event['timestamp'])
    end
  end

  def drop_external_buff_event(event, refresh=false, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if ability_name == 'Dark Transformation'
      drop_external_cooldown('Dark Transformation', target_id, @actors[target_id], event['timestamp'])
      drop_uptime('Dark Transformation', event['timestamp'])
    elsif ability_name == 'Shadow Empowerment'
      drop_cooldown('Dark Arbiter', event['timestamp'])
    end
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if ability_name == 'Dark Arbiter'
      @battlemaiden_id = target_id
      gain_cooldown('Dark Arbiter', event['timestamp'], {damage_done: 0, power_spent: 0})
    end
  end

  def pet_damage_event(event)
    super
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    dt_key = "Dark Transformation-#{@actors[event['sourceID']]}"
    if is_active?(dt_key, event['timestamp'])
      @cooldowns[dt_key][:cp].kpi_hash[:damage_done] += event['amount'].to_i
      @cooldowns[dt_key][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns[dt_key][:cp].details_hash[target_key][:damage] += event['amount'].to_i
      @cooldowns[dt_key][:cp].details_hash[target_key][:hits] += 1
    end
    if event['sourceID'] == @battlemaiden_id
      @cooldowns['Dark Arbiter'][:cp].kpi_hash[:damage_done] += event['amount'].to_i
      @cooldowns['Dark Arbiter'][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns['Dark Arbiter'][:cp].details_hash[target_key][:damage] += event['amount'].to_i
      @cooldowns['Dark Arbiter'][:cp].details_hash[target_key][:hits] += 1
      @cooldowns['Dark Arbiter'][:cp].save unless @cooldowns['Dark Arbiter'][:active]
    end
  end

  def apply_debuff(name, target_id, target_instance, target_is_friendly, timestamp, kpi_hash = {})
    super
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if name == 'Festering Wound'
      self.kpi_hash[:festering_gained] += 1
      self.kpi_hash[:festering_details][target_key] ||= {name: @actors[target_id], gained: 0, popped: 0, capped: 0}
      self.kpi_hash[:festering_details][target_key][:gained] += 1
    end
  end

  def apply_debuff_stack(name, target_id, target_instance, target_is_friendly, stacks, timestamp)
    super
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if name == 'Festering Wound'
      self.kpi_hash[:festering_gained] += 1
      self.kpi_hash[:festering_details][target_key] ||= {name: @actors[target_id], gained: 0, popped: 0, capped: 0}
      self.kpi_hash[:festering_details][target_key][:gained] += 1
    end
  end

  def remove_debuff(name, target_id, target_instance, target_is_friendly, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    stacks = @debuffs['Festering Wound'][target_key][:dp].stacks_array.last[:stacks] rescue 0
    
    super
    
    if name == 'Festering Wound'
      self.kpi_hash[:festering_popped] += stacks
      self.kpi_hash[:festering_details][target_key] ||= {name: @actors[target_id], gained: 0, popped: 0, capped: 0}
      self.kpi_hash[:festering_details][target_key][:popped] += stacks
      if (@debuffs['Soul Reaper'][target_key][:active] rescue false)
        self.kpi_hash[:soulreaper_popped] += stacks
        reaper_timestamp = @debuffs['Soul Reaper'][target_key][:dp].uptimes_array.last[:started_at]
        @debuffs['Soul Reaper'][target_key][:dp].details_hash[reaper_timestamp] ||= []
        @debuffs['Soul Reaper'][target_key][:dp].details_hash[reaper_timestamp] << timestamp
      end
    end
  end

  def remove_debuff_stack(name, target_id, target_instance, target_is_friendly, stacks, timestamp)
    super
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if name == 'Festering Wound'
      self.kpi_hash[:festering_popped] += 1
      self.kpi_hash[:festering_details][target_key] ||= {name: @actors[target_id], gained: 0, popped: 0, capped: 0}
      self.kpi_hash[:festering_details][target_key][:popped] += 1
      if (@debuffs['Soul Reaper'][target_key][:active] rescue false)
        self.kpi_hash[:soulreaper_popped] += 1
        reaper_timestamp = @debuffs['Soul Reaper'][target_key][:dp].uptimes_array.last[:started_at]
        @debuffs['Soul Reaper'][target_key][:dp].details_hash[reaper_timestamp] ||= []
        @debuffs['Soul Reaper'][target_key][:dp].details_hash[reaper_timestamp] << timestamp
      end
    end
  end

  def clean
    super
    self.debuff_parses.where(name: 'Virulent Plague').each do |debuff|
      self.resources_hash[:vplague_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:vplague_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.cooldowns_hash[:transformation_damage] = @kpis['Dark Transformation'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:arbiter_damage] = @kpis['Dark Arbiter'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:apocalypse_damage] = @kpis['Apocalypse'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.save
  end

end