class FightParse::Demonhunter::Vengeance < TankParse
  include Filterable
  self.table_name = :fp_dh_veng

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
      soulcleave_healing: 0,
      soulcleave_overhealing: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      pain_gain: 0,
      pain_waste: 0,
      pain_abilities: {},
      frailty_uptime: 0,
    }
    self.cooldowns_hash = {
      demonspikes_reduced: 0,
      demonspikes_avoided: 0,
      wards_reduced: 0,
      brand_reduced: 0,
      devastation_damage: 0,
    }
    @resources = {
      "r#{ResourceType::PAIN}" => 0,
      "r#{ResourceType::PAIN}_max" => self.max_pain,
    }
    @pain = 0
    @infernal_time
    self.save
  end

  # settings

  def spell_name(id)
    return {
      178740 => 'Immolation Aura',
      204021 => 'Fiery Brand',
      207771 => 'Fiery Brand',
      207744 => 'Fiery Brand',
      204596 => 'Sigil of Flame',
      204598 => 'Sigil of Flame',
      203720 => 'Demon Spikes',
      203819 => 'Demon Spikes',
      218256 => 'Empower Wards',
      183752 => 'Consume Magic',
      228477 => 'Soul Cleave',
      189110 => 'Infernal Strike',
      189112 => 'Infernal Strike',
      213241 => 'Felblade',
      227322 => 'Flame Crash',
      211881 => 'Fel Eruption',
      212084 => 'Fel Devastation',
      207407 => 'Soul Carver',
      224509 => 'Frailty',
      207550 => 'Abyssal Strike',
      236189 => 'Demonic Infusion',
      187827 => 'Metamorphosis',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Metamorphosis'] = {cd: 300}
    local['Demonic Infusion'] = {cd: 120} if talent(6) == 'Demonic Infusion'
    local['Fel Devastation'] = {cd: 60} if talent(5) == 'Fel Devastation'
    local['Fiery Brand'] = {cd: 60}
    local['Soul Carver'] = {cd: 60}
    local['Fel Eruption'] = {cd: 35} if talent(2) == 'Fel Eruption'
    local['Sigil of Flame'] = {cd: 30} unless talent(2) == 'Flame Crash'
    local['Empower Wards'] = {cd: 20}
    local['Infernal Strike'] = {cd: 20} if talent(2) == 'Flame Crash'
    local['Infernal Strike'] = {cd: 12} if talent(0) == 'Abyssal Strike'
    local['Felblade'] = {cd: 15} if talent(2) == 'Felblade'
    local['Immolation Aura'] = {cd: (15 * self.haste_reduction_ratio)}
    local['Demon Spikes'] = {cd: (15 * self.haste_reduction_ratio), extra: 1}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Metamorphosis'] = {cd: 300}
    bars['cd']['Fiery Brand'] = {cd: 60}
    bars['cd']['Empower Wards'] = {cd: 20}
    bars['cd']['Demon Spikes'] = {cd: (15 * self.haste_reduction_ratio), extra: 1}

    return bars
  end

  def cooldown_abilities
    return {
      'Demon Spikes' => {kpi_hash: {reduced_amount: 0}},
      'Empower Wards' => {kpi_hash: {reduced_amount: 0}},
      'Fiery Brand' => {kpi_hash: {reduced_amount: 0}},
      'Fel Devastation' => {kpi_hash: {damage_done: 0}}
    }
  end

  def dps_abilities
    local = {
      'Fel Devastation' => {},
    }
    return super.merge local
  end

  def damage_reduction_abilities
    return [
      {name: 'Demon Spikes', amount: 0.1, details_hash: {avoided: 0}},
      {name: 'Empower Wards', amount: 0.1},
    ]
  end

  def debuff_abilities
    return {
      'Fiery Brand' => {},
      'Frailty' => {},
    }
  end

  def damage_reduction_debuffs
    return {
      'Fiery Brand' => {amount: 0.4},
    }
  end

  def ticks
    local = {
      212105 => 'Fel Devastation',
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::PAIN]
  end

  def max_pain
    return 1000
  end

  def self.latest_version
    return super * 1000 + 3
  end

  def self.latest_hotfix
    return super * 1000 + 2
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::PAIN
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
        @pain = [resource['amount'].to_i - resource['cost'].to_i, 0].max
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::PAIN
      pain_waste = [@pain + event['resourceChange'].to_i - self.max_pain, 0].max
      pain_gain = event['resourceChange'].to_i - pain_waste
      @pain += pain_gain
      self.resources_hash[:pain_gain] += pain_gain
      self.resources_hash[:pain_waste] += pain_waste
      self.resources_hash[:pain_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:pain_abilities][ability_name][:gain] += pain_gain
      self.resources_hash[:pain_abilities][ability_name][:waste] += pain_waste
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Infernal Strike'
      if @infernal_time != event['timestamp']
        @infernal_time = event['timestamp']
        self.casts_hash['Infernal Strike'] ||= []
        self.casts_hash['Infernal Strike'] << event['timestamp']
        save_cast_detail(event, 'Infernal Strike', 'cast')
      end
    end
  end

  def receive_damage_event(event)
    if event['hitType'] == 8 && @cooldowns['Demon Spikes'][:active] && !@cooldowns['Demon Spikes'][:temp] # record parry
      parry_with_spikes(event['sourceID'], event['ability']['guid'], event['ability']['name'])
    end
    super
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Soul Cleave'
      self.kpi_hash[:soulcleave_healing] += event['amount'].to_i
      self.kpi_hash[:soulcleave_overhealing] += event['overheal'].to_i
      # saving as a cooldown might not be the best way, but this is to compare individual casts later
      gain_cooldown('Soul Cleave', event['timestamp'], {healed_amount: event['amount'].to_i, overhealed_amount: event['overheal'].to_i})
      drop_cooldown('Soul Cleave', event['timestamp'] + 1)
    end
  end

  # setters

  def parry_with_spikes(source_id, ability_id, ability_name)
    key = "#{source_id}-#{ability_id}"
    @cooldowns['Demon Spikes'][:cp].details_hash[key] ||= {source: @actors[source_id], name: ability_name, casts: 0, amount: 0, avoided: 0}
    @cooldowns['Demon Spikes'][:cp].details_hash[key][:avoided] += 1
  end

  def clean
    super
    self.resources_hash[:frailty_uptime] = @uptimes['Frailty'][:uptime]
    # calculate total damage avoided with demon spikes
    self.cooldown_parses.where(name: 'Demon Spikes').each do |cd|
      cd.kpi_hash[:avoided_amount] = 0
      cd.details_hash.each do |key, ability|
        if @damage_by_source.has_key?(key)
          ability[:avg] = @damage_by_source[key][:total] / @damage_by_source[key][:count]
        else
          ability[:avg] = 0 #TODO get data from other parses?
        end
        avoided_amount = ability[:avoided] * ability[:avg] * 0.2
        cd.kpi_hash[:avoided_amount] += avoided_amount
        self.cooldowns_hash[:demonspikes_avoided] += avoided_amount
      end
      cd.save
    end
    self.cooldown_parses.where(name: 'Fel Devastation').each do |cd|
      cd.destroy if cd.started_at == cd.ended_at
    end
    self.cooldowns_hash[:demonspikes_reduced] = @kpis['Demon Spikes'].map{|kpi| kpi[:reduced_amount].to_i}.sum rescue 0
    self.cooldowns_hash[:wards_reduced] = @kpis['Empower Wards'].map{|kpi| kpi[:reduced_amount].to_i}.sum rescue 0
    self.cooldowns_hash[:brand_reduced] = @kpis['Fiery Brand'].map{|kpi| kpi[:reduced_amount].to_i}.sum rescue 0
    self.cooldowns_hash[:devastation_damage] = @kpis['Fel Devastation'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
  end

end