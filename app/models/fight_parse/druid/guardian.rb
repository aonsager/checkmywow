class FightParse::Druid::Guardian < TankParse
  include Filterable
  self.table_name = :fp_druid_guardian

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      damage_taken: 0,
      self_heal: 0,
      self_absorb: 0,
      external_heal: 0,
      external_absorb: 0,
    }
    self.resources_hash = {
      mana_spent: 0,
      mana_abilities: 0,
      capped_time: 0,
      rage_gain: 0,
      rage_waste: 0,
      rage_abilities: {},
      mangle_procs: 0,
      mangle_wasted: 0,
      galactic_procs: 0,
      galactic_wasted: 0,
      galactic_notready: 0,
      elune_procs: 0,
      elune_wasted: 0,
      elune_abilities: {},
      ironfur_uptime: 0,
      bristling_gained: 0,
      bristling_wasted: 0,
      moonfire_uptime: 0,
      moonfire_downtime: 0,
      thrash_uptime: 0,
      thrash_downtime: 0,
    }
    self.cooldowns_hash = {
      sleeper_reduced: 0,
      sleeper_damage: 0,
      barkskin_reduced: 0,
      survival_reduced: 0,
      ursol_reduced: 0,
      regen_healed: 0,
      regen_overhealed: 0,
      lunar_damage: 0,
      pulverize_uptime: 0,
    }
    @resources = {
      "r#{ResourceType::RAGE}" => 0,
      "r#{ResourceType::RAGE}_max" => self.max_rage,
    }
    @rage = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      33917 => 'Mangle',
      93622 => 'Mangle!',
      200851 => 'Rage of the Sleeper',
      219432 => 'Rage of the Sleeper',
      22812 => 'Barkskin',
      61336 => 'Survival Instincts',
      155835 => 'Bristling Fur',
      102558 => 'Incarnation: Guardian of Ursoc',
      204066 => 'Lunar Beam',
      204069 => 'Lunar Beam',
      192081 => 'Ironfur',
      22842 => 'Frenzied Regeneration',
      192083 => 'Mark of Ursol',
      8921 => 'Moonfire',
      164812 => 'Moonfire',
      192090 => 'Thrash',
      203964 => 'Galactic Guardian',
      213708 => 'Galactic Guardian',
      155578 => 'Guardian of Elune',
      213680 => 'Guardian of Elune',
      80313 => 'Pulverize',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Survival Instincts'] = {cd: 180 * self.haste_reduction_ratio, extra: 1}
    local['Incarnation: Guardian of Ursoc'] = {cd: 180} if talent(4) == 'Incarnation: Guardian of Ursoc'
    local['Rage of the Sleeper'] = {cd: 90}
    local['Lunar Beam'] = {cd: 90} if talent(6) == 'Lunar Beam'
    local['Barkskin'] = {cd: 90}
    local['Bristling Fur'] = {cd: 40} if talent(0) == 'Bristling Fur'
    local['Frenzied Regeneration'] = {cd: 24 * self.haste_reduction_ratio, extra: 1}
    local['Mangle'] = {cd: 6}
    local['Ironfur'] = {cd: nil}
    local['Mark of Ursol'] = {cd: nil}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Survival Instincts'] = {cd: 180 * self.haste_reduction_ratio, extra: 1}
    bars['cd']['Incarnation: Guardian of Ursoc'] = {cd: 180} if talent(4) == 'Incarnation: Guardian of Ursoc'
    bars['cd']['Rage of the Sleeper'] = {cd: 90}
    bars['cd']['Lunar Beam'] = {cd: 90} if talent(6) == 'Lunar Beam'
    bars['cd']['Barkskin'] = {cd: 90}
    bars['cd']['Mark of Ursol'] = {}
    bars['cd']['Bristling Fur'] = {cd: 40} if talent(0) == 'Bristling Fur'
    bars['cd']['Frenzied Regeneration'] = {cd: 24 * self.haste_reduction_ratio, extra: 1}

    return bars
  end

  def cooldown_abilities
    return {
      'Survival Instincts' => {kpi_hash: {reduced_amount: 0}},
      'Rage of the Sleeper' => {kpi_hash: {reduced_amount: 0, damage_done: 0}},
      'Barkskin' => {kpi_hash: {reduced_amount: 0}},
      'Mark of Ursol' => {kpi_hash: {reduced_amount: 0}},
      'Frenzied Regeneration' => {kpi_hash: {damage_done: 0, healing_done: 0, overhealing_done: 0}},
      'Lunar Beam' => {kpi_hash: {damage_done: 0, healing_done: 0, overhealing_done: 0}},
      'Bristling Fur' => {kpi_hash: {rage_gained: 0, rage_wasted: 0}},
    }
  end

  def uptime_abilities
    local = {
      'Guardian of Elune' => {},
      'Galactic Guardian' => {},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Lunar Beam' => {},
    }
    return super.merge local
  end

  def damage_reduction_abilities
    return [
      {name: 'Survival Instincts', amount: 0.5},
      {name: 'Rage of the Sleeper', amount: 0.25},
      {name: 'Barkskin', amount: 0.2},
      {name: 'Mark of Ursol', exclude_type: 1, amount: 0.3}, # no physical damage
    ]
  end

  def buff_abilities
    return {
      'Ironfur' => {},
    }
  end

  def debuff_abilities
    return {
      'Moonfire' => {},
      'Thrash' => {target_stacks: 3},
    }
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  def max_rage
    return 100
  end

  def track_resources
    return [ResourceType::RAGE]
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if @uptimes['Guardian of Elune'][:active] && ['Ironfur', 'Mark of Ursol', 'Frenzied Regeneration'].include?(ability_name)
      self.resources_hash[:elune_abilities][ability_name] ||= {name: ability_name, casts: 0}
      self.resources_hash[:elune_abilities][ability_name][:casts] += 1
    end
    if ability_name == 'Moonfire' && !@uptimes['Galactic Guardian'][:active]
      self.resources_hash[:galactic_notready] += 1 
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::RAGE
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
        @rage = [resource['amount'].to_i - resource['cost'].to_i, 0].max / 10
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::RAGE
      rage_waste = [@rage + event['resourceChange'].to_i - self.max_rage, 0].max
      rage_gain = event['resourceChange'].to_i - rage_waste
      @rage += rage_gain
      self.resources_hash[:rage_gain] += rage_gain
      self.resources_hash[:rage_waste] += rage_waste
      self.resources_hash[:rage_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:rage_abilities][ability_name][:gain] += rage_gain
      self.resources_hash[:rage_abilities][ability_name][:waste] += rage_waste
      if ability_name == 'Bristling Fur'
        @cooldowns['Bristling Fur'][:cp].kpi_hash[:rage_gained] += rage_gain
        @cooldowns['Bristling Fur'][:cp].kpi_hash[:rage_wasted] += rage_waste
      end
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}-damage"

    if ability_name == 'Rage of the Sleeper'
      @cooldowns['Rage of the Sleeper'][:cp].kpi_hash[:damage_done] = @cooldowns['Rage of the Sleeper'][:cp].kpi_hash[:damage_done].to_i + event['amount'].to_i
      @cooldowns['Rage of the Sleeper'][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns['Rage of the Sleeper'][:cp].details_hash[target_key][:damage] += event['amount'].to_i
      @cooldowns['Rage of the Sleeper'][:cp].details_hash[target_key][:hits] += 1
      @cooldowns['Rage of the Sleeper'][:cp].ended_at = event['timestamp']
    end
  end

  def refresh_self_buff_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:elune_wasted] += 1 if ability_name == 'Guardian of Elune'
    self.resources_hash[:mangle_wasted] += 1 if ability_name == 'Mangle!'
    self.resources_hash[:galactic_wasted] += 1 if ability_name == 'Galactic Guardian'
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:elune_procs] += 1 if ability_name == 'Guardian of Elune'
    self.resources_hash[:mangle_procs] += 1 if ability_name == 'Mangle!'
    self.resources_hash[:galactic_procs] += 1 if ability_name == 'Galactic Guardian'
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Lunar Beam'
      @cooldowns['Lunar Beam'][:cp].kpi_hash[:healing_done] += event['amount'].to_i
      @cooldowns['Lunar Beam'][:cp].kpi_hash[:overhealing_done] += event['overheal'].to_i
    elsif ability_name == 'Frenzied Regeneration'
      @cooldowns['Frenzied Regeneration'][:cp].kpi_hash[:healing_done] += event['amount'].to_i
      @cooldowns['Frenzied Regeneration'][:cp].kpi_hash[:overhealing_done] += event['overheal'].to_i
    end
  end

  # setters

  def clean
    super
    self.resources_hash[:ironfur_uptime] = @kpis['Ironfur'].first[:uptime].to_i rescue 0
    self.debuff_parses.where(name: 'Moonfire').each do |debuff|
      # ignore mobs active for less than 10 seconds
      next if debuff.kpi_hash[:uptime].to_i + debuff.kpi_hash[:downtime].to_i < 10000
      self.resources_hash[:moonfire_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:moonfire_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.debuff_parses.where(name: 'Thrash').each do |debuff|
      # ignore mobs active for less than 20 seconds
      next if debuff.kpi_hash[:uptime].to_i + debuff.kpi_hash[:downtime].to_i < 20000
      self.resources_hash[:thrash_uptime] += debuff.kpi_hash[:stacks_uptime].to_i
      self.resources_hash[:thrash_downtime] += (debuff.kpi_hash[:uptime].to_i + debuff.kpi_hash[:downtime].to_i - debuff.kpi_hash[:stacks_uptime].to_i)
    end
    self.resources_hash[:bristling_gained] = @kpis['Bristling Fur'].map{|kpi| kpi[:rage_gained]}.sum rescue 0
    self.resources_hash[:bristling_wasted] = @kpis['Bristling Fur'].map{|kpi| kpi[:rage_wasted]}.sum rescue 0
    self.cooldowns_hash[:regen_healed] = @kpis['Frenzied Regeneration'].map{|kpi| kpi[:healing_done]}.sum rescue 0
    self.cooldowns_hash[:regen_overhealed] = @kpis['Frenzied Regeneration'].map{|kpi| kpi[:overhealing_done]}.sum rescue 0
    self.cooldowns_hash[:sleeper_reduced] = @kpis['Rage of the Sleeper'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:sleeper_damage] = @kpis['Rage of the Sleeper'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:survival_reduced] = @kpis['Survival Instincts'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:ursol_reduced] = @kpis['Mark of Ursol'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:barkskin_reduced] = @kpis['Barkskin'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:lunar_damage] = @kpis['Lunar Beam'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:lunar_healing] = @kpis['Lunar Beam'].map{|kpi| kpi[:healing_done]}.sum rescue 0
    self.cooldowns_hash[:lunar_overhealing] = @kpis['Lunar Beam'].map{|kpi| kpi[:overhealing_done]}.sum rescue 0
    self.cooldowns_hash[:pulverize_uptime] = @kpis['Pulverize'].first[:uptime].to_i rescue 0
  end

end