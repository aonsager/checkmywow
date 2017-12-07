class FightParse::Deathknight::Blood < TankParse
  include Filterable
  self.table_name = :fp_dk_blood

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      damage_taken: 0,
      self_heal: 0,
      self_absorb: 0,
      external_heal: 0,
      external_absorb: 0,
      bs_uptime: 0,
      ds_heal: 0,
      ds_overheal: 0,
      ds_count: 0,
      ds_no_ossuary: 0,
    }
    self.resources_hash = {
      rp_capped_time: 0,
      rp_spent: 0,
      rp_gain: 0,
      rp_waste: 0,
      rp_abilities: {},
      runes_capped_time: 0,
      cs_procs: 0,
      dd_with_cs: 0,
      dd_uptime: 0,
      bs_gain: 0,
      bs_waste: 0,
      bs_waste_details: [],
      bp_uptime: 0,
      bp_downtime: 0,
    }
    self.cooldowns_hash = {
      consumption_damage: 0,
      ams_reduced: 0,
      icebound_reduced: 0,
      drw_parried: 0,
      vb_healed: 0,
      vb_overhealed: 0,
      bonestorm_damage: 0,
      mirror_damage: 0,
    }
    @resources = {
      "r#{ResourceType::RUNICPOWER}" => 0,
      "r#{ResourceType::RUNICPOWER}_max" => self.max_runicpower,
      "r#{ResourceType::RUNES}" => 0,
      "r#{ResourceType::RUNES}_max" => 6,
    }
    @runicpower = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      43265 => 'Death and Decay',
      188290 => 'Death and Decay (buff)',
      81141 => 'Crimson Scourge',
      49998 => 'Death Strike',
      45470 => 'Death Strike',
      195182 => 'Marrowrend',
      205223 => 'Consumption',
      205224 => 'Consumption',
      206930 => 'Heart Strike',
      48707 => 'Anti-Magic Shell',
      81256 => 'Dancing Rune Weapon',
      49028 => 'Dancing Rune Weapon',
      55233 => 'Vampiric Blood',
      195181 => 'Bone Shield',
      219788 => 'Ossuary',
      219786 => 'Ossuary',
      55078 => 'Blood Plague',
      206977 => 'Blood Mirror',
      221847 => 'Blood Mirror',
      194844 => 'Bonestorm',
      50842 => 'Blood Boil',
      205723 => 'Red Thirst',
      48792 => 'Icebound Fortitude',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Dancing Rune Weapon'] = {cd: 180}
    local['Icebound Fortitude'] = {cd: 180}
    local['Blood Mirror'] = {cd: 120} if talent(6) == 'Blood Mirror'
    local['Bonestorm'] = {cd: 60} if talent(6) == 'Bonestorm'
    local['Vampiric Blood'] = {cd: 60}
    local['Vampiric Blood'][:reduction] = self.resources_hash[:rp_spent].to_i / 6 if talent(3) == 'Red Thirst'
    local['Consumption'] = {cd: 45}
    local['Death and Decay'] = {cd: 30, extra: self.resources_hash[:cs_procs]}
    local['Blood Boil'] = {cd: 7.5, extra: 1}

    return super.merge local
  end

  def uptime_abilities
    local = {
      'Crimson Scourge' => {},
      'Ossuary' => {},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Bone Shield' => {},
      'Death and Decay (buff)' => {},
    }
    local['Bone Shield'][:target_stacks] = 5 if talent(2) == 'Ossuary'
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Anti-Magic Shell' => {kpi_hash: {reduced_amount: 0}},
      'Dancing Rune Weapon' => {kpi_hash: {reduced_amount: 0}},
      'Icebound Fortitude' => {kpi_hash: {reduced_amount: 0}},
      'Vampiric Blood' => {kpi_hash: {healed_amount: 0, overhealed_amount: 0}},
      'Consumption' => {kpi_hash: {damage_done: 0, healing_done: 0, overhealing_done: 0}},
      'Blood Mirror' => {kpi_hash: {damage_done: 0, reduced_amount: 0}},
      'Bonestorm' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Consumption' => {},
      'Bonestorm' => {channel: true},
    }
    return super.merge local
  end

  def damage_reduction_abilities
    return [
      {name: 'Blood Mirror', amount: 0.2},
      {name: 'Icebound Fortitude', amount: 0.3},
    ]
  end

  def debuff_abilities
    local = {
      'Blood Plague' => {},
    }
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Dancing Rune Weapon'] = {cd: 180}
    bars['cd']['Icebound Fortitude'] = {cd: 180}
    bars['cd']['Vampiric Blood'] = {cd: 60}
    bars['cd']['Vampiric Blood'][:reduction] = self.resources_hash[:rp_spent].to_i / 6 if talent(3) == 'Red Thirst'
    bars['cd']['Anti-Magic Shell'] = {cd: 45}
    bars['cd']['Consumption'] = {cd: 45}
    return bars
  end

  def track_resources
    return [ResourceType::RUNICPOWER]
  end

  def show_resources
    return [ResourceType::RUNICPOWER, ResourceType::RUNES]
  end

  def max_runicpower
    return @uptimes['Ossuary'][:active] ? 125 : 115
  end

  def max_boneshield
    return 10
  end

  def marrowrend_max_stacks
    if artifact('Rattling Bones')
      return self.max_boneshield - 4 * (@cooldowns['Dancing Rune Weapon'][:active] ? 2 : 1)
    else
      return self.max_boneshield - 3 * (@cooldowns['Dancing Rune Weapon'][:active] ? 2 : 1)
    end
  end

  def vamp_ratio
    return 0.3
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
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Death and Decay' && @uptimes['Crimson Scourge'][:active]
      self.resources_hash[:dd_with_cs] += 1 
    end
    if ability_name == 'Death Strike' 
      self.kpi_hash[:ds_count] += 1
      if !@uptimes['Ossuary'][:active]
        self.kpi_hash[:ds_no_ossuary] += 1
      end
    end
    if ability_name == 'Marrowrend'
      wasted = @buffs['Bone Shield'][:bp].stacks_array.last[:stacks] - marrowrend_max_stacks rescue 0
      if wasted > 0
        self.resources_hash[:bs_waste] += wasted 
        self.resources_hash[:bs_waste_details] << {timestamp: event['timestamp'], msg: "Marrowrend cast at #{@buffs['Bone Shield'][:bp].stacks_array.last[:stacks]}#{' with Dancing Rune Weapon active' if @cooldowns['Dancing Rune Weapon'][:active]}"}
      end
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::RUNICPOWER
        check_resource_cap(resource['amount'].to_i, resource['max'].to_i, event['timestamp'], 'rp')
        self.resources_hash[:rp_spent] += resource['cost'].to_i / 10
        @runicpower = [resource['amount'].to_i - resource['cost'].to_i, 0].max / 10
      elsif resource['type'] == ResourceType::RUNES
        check_resource_cap(resource['amount'].to_i, resource['max'].to_i, event['timestamp'], 'runes')
      end
      
    end
    
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::RUNICPOWER
      runicpower_waste = [@runicpower + event['resourceChange'].to_i - self.max_runicpower, 0].max
      runicpower_gain = event['resourceChange'].to_i - runicpower_waste
      @runicpower += runicpower_gain
      self.resources_hash[:rp_gain] += runicpower_gain
      self.resources_hash[:rp_waste] += runicpower_waste
      self.resources_hash[:rp_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:rp_abilities][ability_name][:gain] += runicpower_gain
      self.resources_hash[:rp_abilities][ability_name][:waste] += runicpower_waste
    end
  end

  def absorb_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) 
    if ability_name == 'Anti-Magic Shell' && @cooldowns['Anti-Magic Shell'][:active] && !@cooldowns['Anti-Magic Shell'][:temp]
      source_key = "#{event['attackerID']}-#{event['attackerInstance']}-#{event['extraAbility']['guid']}"
      @cooldowns['Anti-Magic Shell'][:cp].details_hash[source_key] ||= {source: @actors[event['attackerID']], name: event['extraAbility']['name'], casts: 0, amount: 0}
      @cooldowns['Anti-Magic Shell'][:cp].details_hash[source_key][:casts] += 1
      @cooldowns['Anti-Magic Shell'][:cp].details_hash[source_key][:amount] += event['amount'] # check absorbed amount
      @cooldowns['Anti-Magic Shell'][:cp].kpi_hash[:reduced_amount] += event['amount']
    end
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Death Strike'
      self.kpi_hash[:ds_heal] += event['amount'].to_i
      self.kpi_hash[:ds_overheal] += event['overheal'].to_i
      # saving as a cooldown might not be the best way, but this is to compare individual casts later
      gain_cooldown('Death Strike', event['timestamp'], {healed_amount: event['amount'].to_i, overhealed_amount: event['overheal'].to_i})
      drop_cooldown('Death Strike', event['timestamp'] + 1)
    elsif ability_name == 'Consumption'
      @cooldowns['Consumption'][:cp].kpi_hash[:healing_done] += event['amount'].to_i
      @cooldowns['Consumption'][:cp].kpi_hash[:overhealing_done] += event['overheal'].to_i
    end
    self.vampiric_heal(event) if @cooldowns['Vampiric Blood'][:active]
  end

  def receive_heal_event(event)
    super
    self.vampiric_heal(event) if @cooldowns['Vampiric Blood'][:active]
  end

  def vampiric_heal(event)
    key = "#{event['sourceID']}-#{event['ability']['guid']}"
      @cooldowns['Vampiric Blood'][:cp].details_hash[key] ||= {source: @actors[event['sourceID']], name: event['ability']['name'], casts: 0, amount: 0, overheal_amount: 0}
      @cooldowns['Vampiric Blood'][:cp].details_hash[key][:casts] += 1
      amount = ((event['amount'].to_i + event['overheal'].to_i) * (1 - 1 / (1 + vamp_ratio))).to_i
      overheal = [amount, event['overheal'].to_i].min
      heal = amount - overheal
      @cooldowns['Vampiric Blood'][:cp].details_hash[key][:amount] += heal
      @cooldowns['Vampiric Blood'][:cp].details_hash[key][:overheal_amount] += overheal
      @cooldowns['Vampiric Blood'][:cp].kpi_hash[:healed_amount] += heal
      @cooldowns['Vampiric Blood'][:cp].kpi_hash[:overhealed_amount] += overheal
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Crimson Scourge'
      self.resources_hash[:cs_procs] += 1
    end
  end

  def gain_self_buff_stack_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:bs_gain] += 1 if ability_name == 'Bone Shield'
  end

  def receive_damage_event(event)
    if event['hitType'] == 8 && @cooldowns['Dancing Rune Weapon'][:active] # record parry
      parry_with_drw(event['sourceID'], event['ability']['guid'], event['ability']['name'])
    end
    super
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Blood Mirror' and @cooldowns['Blood Mirror'][:active]
      @cooldowns['Blood Mirror'][:cp].kpi_hash[:damage_done] += event['amount'].to_i
    end
  end

  # setters

  def parry_with_drw(source_id, ability_id, ability_name)
    source ||= -1
    key = "#{source_id}-#{ability_id}"
    @cooldowns['Dancing Rune Weapon'][:cp].details_hash[key] ||= {source: @actors[source_id], name: ability_name, parried: 0, avg: 0}
    @cooldowns['Dancing Rune Weapon'][:cp].details_hash[key][:parried] += 1
  end

  def clean
    super
    self.resources_hash[:dd_uptime] = @kpis['Death and Decay (buff)'].first[:uptime].to_i rescue 0
    self.resources_hash[:rp_capped_time] = self.resources_hash[:rp_capped_time].to_i / 1000
    self.resources_hash[:runes_capped_time] = self.resources_hash[:runes_capped_time].to_i / 1000
    self.cooldown_parses.where(name: 'Dancing Rune Weapon').each do |drw|
      if drw.ended_at == drw.started_at
        drw.destroy
        next
      end
      drw.kpi_hash[:reduced_amount] = 0
      drw.details_hash.each do |key, ability|
        if @damage_by_source.has_key?(key)
          ability[:avg] = @damage_by_source[key][:total] / @damage_by_source[key][:count]
        else
          ability[:avg] = 0 #TODO get data from other parses?
        end
        avoided_dmg = ability[:parried] * ability[:avg]
        drw.kpi_hash[:reduced_amount] += avoided_dmg
      end
      self.cooldowns_hash[:drw_parried] += drw.kpi_hash[:reduced_amount]
      drw.save
    end
    self.resources_hash[:bp_uptime] = @uptimes['Blood Plague'][:uptime] rescue 0
    if self.talent(2) == 'Ossuary'
      self.kpi_hash[:bs_uptime] = @buffs['Bone Shield'][:bp].kpi_hash[:stacks_uptime].to_i rescue 0
    else
      self.kpi_hash[:bs_uptime] = @kpis['Bone Shield'].first[:uptime].to_i rescue 0
    end
    self.cooldowns_hash[:ams_reduced] = @kpis['Anti-Magic Shell'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:icebound_reduced] = @kpis['Icebound Fortitude'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:vb_healed] = @kpis['Vampiric Blood'].map{|kpi| kpi[:healed_amount]}.sum rescue 0
    self.cooldowns_hash[:vb_overhealed] = @kpis['Vampiric Blood'].map{|kpi| kpi[:overhealed_amount]}.sum rescue 0
    self.cooldowns_hash[:consumption_damage] = @kpis['Consumption'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:consumption_healing] = @kpis['Consumption'].map{|kpi| kpi[:healing_done]}.sum rescue 0
    self.cooldowns_hash[:consumption_overhealing] = @kpis['Consumption'].map{|kpi| kpi[:overhealing_done]}.sum rescue 0
    self.cooldowns_hash[:bonestorm_damage] = @kpis['Bonestorm'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:mirror_damage] = @kpis['Blood Mirror'].map{|kpi| kpi[:damage_done]}.sum rescue 0
  end

end