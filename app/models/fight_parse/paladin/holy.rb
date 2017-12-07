class FightParse::Paladin::Holy < HealerParse
  include Filterable
  self.table_name = :fp_paladin_holy

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
    }
    self.resources_hash = {
      mana_spent: 0,
      heal_per_mana: {},
      infusion_procs: 0,
      infusion_used: 0,
      infusion_casts: {'Holy Light' => 0, 'Flash of Light' => 0},
    }
    self.cooldowns_hash = {
      wrath_healing: 0,
      wrath_overhealing: 0,
      avenger_healing: 0,
      avenger_overhealing: 0,
      sacrifice_healing: 0,
      sacrifice_overhealing: 0,
      protection_healing: 0,
      protection_overhealing: 0,
      layonhands_healing: 0,
      layonhands_overhealing: 0,
      devotion_reduced: 0,
    }
    @check_abc = true
    self.save
  end

  # settings

  def spell_name(id)
    return {
      20473 => 'Holy Shock',
      85222 => 'Light of Dawn',
      223306 => 'Bestow Faith',
      114165 => 'Holy Prism',
      200652 => 'Tyr\'s Deliverance',
      31842 => 'Avenging Wrath',
      105809 => 'Holy Avenger',
      6940 => 'Blessing of Sacrifice',
      498 => 'Divine Protection',
      31821 => 'Aura Mastery',
      633 => 'Lay on Hands',
      53576 => 'Infusion of Light',
      54149 => 'Infusion of Light',
      82326 => 'Holy Light',
      19750 => 'Flash of Light',
    }[id] || super(id)
  end

  def uptime_abilities
    local = {
      'Infusion of Light' => {},
    }
    return super.merge local
  end

  def track_casts
    local = {}
    local['Tyr\'s Deliverance'] = {cd: 90}
    local['Holy Prism'] = {cd: 20} if talent(4) == 'Holy Prism'
    local['Light of Dawn'] = {cd: 12}
    local['Bestow Faith'] = {cd: 12} if talent(0) == 'Bestow Faith'
    local['Holy Shock'] = {cd: 9}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['heal']['Lay on Hands'] = {cd: 600}
    bars['cd']['Aura Mastery'] = {cd: 180}
    bars['external_absorb']['Blessing of Sacrifice'] = {cd: 150}
    bars['cd']['Avenging Wrath'] = {cd: 120}
    bars['cd']['Holy Avenger'] = {cd: 90}
    bars['cd']['Divine Protection'] = {cd: 60}

    return bars
  end

  def healing_abilities
    local = [
      'Lay on Hands',
    ]
    return super + local
  end

  def healing_buff_abilities
    return {
      'Avenging Wrath' => {},
      'Holy Avenger' => {},
    }
  end

  def absorbing_abilities
    local = [
      'Blessing of Sacrifice',
    ]
    return super + local
  end

  def damage_reduction_cooldowns
    local = {
      'Divine Protection' => {percent: 0.2},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Lay on Hands' => {kpi_hash: {healing_done: 0, overhealing_done: 0}},
      'Aura Mastery' => {kpi_hash: {aura: nil, healing_done: 0, overhealing_done: 0, damage_reduced: 0}},
      'Blessing of Sacrifice' => {kpi_hash: {damage_reduced: 0, damage_done: 0}},
      'Avenging Wrath' => {kpi_hash: {healing_increase: 0, overhealing_increase: 0}},
      'Holy Avenger' => {kpi_hash: {healing_increase: 0, overhealing_increase: 0}},
      'Divine Protection' => {kpi_hash: {damage_reduced: 0}},
    }
    return super.merge local
  end

  def show_resources
    return [ResourceType::MANA]
  end

  def self.latest_version
    return super * 1000 + 1
  end

  # getters

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if @uptimes['Infusion of Light'][:active] && ['Holy Light', 'Flash of Light'].include?(ability_name)
      self.resources_hash[:infusion_used] += 1
      self.resources_hash[:infusion_casts][ability_name] += 1
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:infusion_procs] += 1 if ability_name == 'Infusion of Light'
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return unless @player_ids.include?(target_id)
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    
  end

  # setters

  def clean
    super
    
    self.cooldowns_hash[:layonhands_healing] = @kpis['Lay on Hands'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:layonhands_overhealing] = @kpis['Lay on Hands'].map{|kpi| kpi[:overhealing_done].to_i + kpi[:leftover_absorb].to_i}.sum rescue 0
    self.cooldowns_hash[:wrath_healing] = @kpis['Avenging Wrath'].map{|kpi| kpi[:healing_increase].to_i }.sum rescue 0
    self.cooldowns_hash[:wrath_overhealing] = @kpis['Avenging Wrath'].map{|kpi| kpi[:overhealing_increase].to_i + kpi[:leftover_absorb].to_i}.sum rescue 0
    self.cooldowns_hash[:avenger_healing] = @kpis['Holy Avenger'].map{|kpi| kpi[:healing_increase].to_i }.sum rescue 0
    self.cooldowns_hash[:avenger_overhealing] = @kpis['Holy Avenger'].map{|kpi| kpi[:overhealing_increase].to_i + kpi[:leftover_absorb].to_i}.sum rescue 0

    self.save
  end

end