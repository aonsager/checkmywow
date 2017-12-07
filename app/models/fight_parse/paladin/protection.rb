class FightParse::Paladin::Protection < TankParse
  include Filterable
  self.table_name = :fp_paladin_prot

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      damage_taken: 0,
      self_heal: 0,
      self_absorb: 0,
      external_heal: 0,
      external_absorb: 0,
      protector_casts: {0=>0, 10=>0, 20=>0, 30=>0, 40=>0},
      protector_values: [],
    }
    self.resources_hash = {
      shield_uptime: 0,
      consecration_uptime: 0,
      casts: 0,
      cpm: 0,
    }
    self.cooldowns_hash = {
      eye_of_tyr_reduced: 0,
      ardent_defender_reduced: 0,
      avenging_wrath_damage: 0,
      avenging_wrath_healing: 0,
      avenging_wrath_overhealing: 0,
      guardian_reduced: 0,
    }
    self.save
  end

  # settings

  def spell_name(id)
    return {
      209202 => 'Eye of Tyr',
      20271 => 'Judgment',
      204019 => 'Blessed Hammer',
      204301 => 'Blessed Hammer',
      53595 => 'Hammer of the Righteous',
      26573 => 'Consecration',
      188370 => 'Consecration',
      31935 => 'Avenger\'s Shield',
      53600 => 'Shield of the Righteous',
      132403 => 'Shield of the Righteous',
      31850 => 'Ardent Defender',
      31884 => 'Avenging Wrath',
      86659 => 'Guardian of Ancient Kings',
      184092 => 'Light of the Protector',
      213652 => 'Hand of the Protector',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Blessed Hammer'] = {cd: (4.5 * self.haste_reduction_ratio), extra: 2} if talent(0) == 'Blessed Hammer'
    local['Hammer of the Righteous'] = {cd: (4.5 * self.haste_reduction_ratio), extra: 1} if talent(0) != 'Blessed Hammer'
    local['Consecration'] = {cd: 9}
    # local['Judgment'] = {cd: (12 * self.haste_reduction_ratio)}
    # local['Avenger\'s Shield'] = {cd: 15}
    local['Eye of Tyr'] = {cd: 60}
    local['Ardent Defender'] = {cd: 120}
    local['Avenging Wrath'] = {cd: 120}
    local['Guardian of Ancient Kings'] = {cd: 300}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Eye of Tyr'] = {cd: 60}
    bars['cd']['Ardent Defender'] = {cd: 120}
    bars['cd']['Avenging Wrath'] = {cd: 120}
    bars['cd']['Guardian of Ancient Kings'] = {cd: 300}
    return bars
  end

  def cooldown_abilities
    return {
      'Eye of Tyr' => {kpi_hash: {reduced_amount: 0}},  
      'Ardent Defender' => {kpi_hash: {reduced_amount: 0}},
      'Avenging Wrath' => {kpi_hash: {damage_done: 0, healing_done: 0}},
      'Guardian of Ancient Kings' => {kpi_hash: {reduced_amount: 0}},
    }
  end

  def damage_reduction_abilities
    return [
      {name: 'Ardent Defender', amount: 0.2},
      {name: 'Guardian of Ancient Kings', amount: 0.5},
    ]
  end

  def damage_reduction_debuffs
    return {
      'Eye of Tyr' => {amount: 0.25},
    }
  end

  def dps_buff_abilities
    local = {
      'Avenging Wrath' => {percent: 0.35},
    }
    return super.merge local
  end

  def uptime_abilities
    local = {
      'Consecration' => {},
    }
    return super.merge local
  end

  def buff_abilities
    return {
      'Shield of the Righteous' => {},
      'Consecration' => {},
    }
  end

  def debuff_abilities
    return {
      'Eye of Tyr' => {},  
      'Blessed Hammer' => {},
    }
  end

  # getters

  # event handlers

  def cast_event(event)
    super
    self.resources_hash[:casts] += 1
  end 

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    amount = event['amount'].to_i
    overhealing = event['overheal'].to_i
    if ability_name == 'Light of the Protector' || ability_name == 'Hand of the Protector'
      percent = 100 * amount / event['maxHitPoints'] rescue 0
      self.kpi_hash[:protector_casts][10 * (percent/10)] = self.kpi_hash[:protector_casts][10 * (percent/10)].to_i + 1
      self.kpi_hash[:protector_values] << percent
    end
    if @cooldowns['Avenging Wrath'][:active] && !@cooldowns['Avenging Wrath'][:temp]
      increased_amount = (amount - amount / (1 + 0.35)).to_i
      increased_overhealing = (overhealing - overhealing / (1 + 0.35)).to_i
      @cooldowns['Avenging Wrath'][:cp].kpi_hash[:healing_increase] = @cooldowns['Avenging Wrath'][:cp].kpi_hash[:healing_increase].to_i + increased_amount
      @cooldowns['Avenging Wrath'][:cp].kpi_hash[:overhealing_increase] = @cooldowns['Avenging Wrath'][:cp].kpi_hash[:overhealing_increase].to_i + increased_overhealing
      @cooldowns['Avenging Wrath'][:cp].details_hash[ability_name] ||= {name: ability_name, damage: 0, hits: 0, healing: 0, overhealing: 0}
      @cooldowns['Avenging Wrath'][:cp].details_hash[ability_name][:healing] += increased_amount
      @cooldowns['Avenging Wrath'][:cp].details_hash[ability_name][:overhealing] += increased_overhealing
      @cooldowns['Avenging Wrath'][:cp].details_hash[ability_name][:hits] += 1
    end
  end

  def clean
    super
    aggregate_debuffs
    self.resources_hash[:cpm] = (60.0 * self.resources_hash[:casts] / self.fight_time).round(1)
    self.resources_hash[:shield_uptime] = @kpis['Shield of the Righteous'].first[:uptime].to_i rescue 0
    self.resources_hash[:consecration_uptime] = @kpis['Consecration'].first[:uptime].to_i rescue 0
    self.cooldowns_hash[:eye_of_tyr_reduced] = @kpis['Eye of Tyr'].map{|kpi| kpi[:reduced_amount].to_i}.sum rescue 0
    self.cooldowns_hash[:ardent_defender_reduced] = @kpis['Ardent Defender'].map{|kpi| kpi[:reduced_amount].to_i}.sum rescue 0
    self.cooldowns_hash[:avenging_wrath_damage] = @kpis['Avenging Wrath'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:avenging_wrath_healing] = @kpis['Avenging Wrath'].map{|kpi| kpi[:healing_increase].to_i}.sum rescue 0
    self.cooldowns_hash[:avenging_wrath_overhealing] = @kpis['Avenging Wrath'].map{|kpi| kpi[:overhealing_increase].to_i}.sum rescue 0
    self.cooldowns_hash[:guardian_reduced] = @kpis['Guardian of Ancient Kings'].map{|kpi| kpi[:reduced_amount].to_i}.sum rescue 0
    save
  end
end