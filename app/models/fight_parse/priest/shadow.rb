class FightParse::Priest::Shadow < FightParse
  include Filterable
  self.table_name = :fp_priest_shadow

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 5
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      voidray_uptime: 0,
      shadowy_procs: 0,
    }
    self.resources_hash = {
      pain_uptime: 0,
      pain_downtime: 0,
      vampiric_uptime: 0,
      vampiric_downtime: 0,
      voidform_uptime: 0,
      insanity_gained: 0,
      insanity_wasted: 0,
      void_insanity_gained: 0,
      void_insanity_wasted: 0,
      insanity_abilities: {},
    }
    self.cooldowns_hash = {
      voidform_damage: 0,
      power_damage: 0,
    }
    @check_abc = true
    @insanity = 0
    self.save
    # to track damage done
    gain_cooldown('Shadow Word: Death', self.started_at, {damage_done: 0})
  end

  # settings

  def self.score_categories
    return {
      'casts_score' => 'Casts',
      'voidform_uptime' => 'Voidform Uptime',
    }
  end

  def track_casts
    local = {}
    local['Power Infusion'] = {cd: 120} if talent(5) == 'Power Infusion'
    local['Mindbender'] = {cd: 60} if talent(5) == 'Mindbender'
    local['Void Torrent'] = {cd: 60, buff: 'Voidform', name: 'Void Torrent'}
    local['Shadow Crash'] = {cd: 30} if talent(5) == 'Shadow Crash'
    local['Shadow Word: Void'] = {cd: (20 * self.haste_reduction_ratio).to_i, extra: 2} if talent(0) == 'Shadow Word: Void'
    local['Mind Blast'] = {cd: (9 * self.haste_reduction_ratio).to_i, extra: self.kpi_hash[:shadowy_procs].to_i}
    local['Void Bolt'] = {cd: 4.5, buff: 'Voidform', name: 'Void Bolt'}
    
    return super.merge local
  end

  def channel_abilities
    return super + [
      'Void Torrent',
    ]
  end

  def ignore_casts
    return super + [
      'Shadowy Apparition'
    ]
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Voidform'] = {cd: nil}
    bars['pet']['Shadowfiend'] = {cd: 180, optional: true, color: 'orange'} if talent(5) != 'Mindbender'
    bars['pet']['Mindbender'] = {cd: 60, optional: true, color: 'orange'} if talent(5) == 'Mindbender'
    
    return bars
  end

  def uptime_abilities
    local = {
      'Shadowy Insight' => {},
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Shadow Word: Pain' => {},
      'Vampiric Touch' => {},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Void Ray' => {target_stacks: 4},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Voidform' => {kpi_hash: {damage_done: 0, insanity_gained: 0, insanity_wasted: 0, insanity_abilities: {}}},
      'Power Infusion' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Shadow Word: Death' => {channel: true},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Voidform' => {},
      'Power Infusion' => {},
    }
    return super.merge local
  end

  def max_insanity
    return 100
  end

  # getters

  def spell_name(id)
    return {
      589 => 'Shadow Word: Pain',
      34914 => 'Vampiric Touch',
      32379 => 'Shadow Word: Death',
      125927 => 'Shadow Word: Death',
      8092 => 'Mind Blast',
      162452 => 'Shadowy Insight',
      124430 => 'Shadowy Insight',
      123040 => 'Mindbender',
      205448 => 'Void Bolt',
      205351 => 'Shadow Word: Void',
      10060 => 'Power Infusion',
      205385 => 'Shadow Crash',
      185916 => 'Voidform',
      194249 => 'Voidform',
      205371 => 'Void Ray',
      205372 => 'Void Ray',
      205065 => 'Void Torrent',
      147193 => 'Shadowy Apparition',
    }[id] || super(id)
  end

  def show_resources
    return [ResourceType::INSANITY]
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::INSANITY
        @insanity = [resource['amount'].to_i - resource['cost'].to_i, 0].max / 100
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    self.kpi_hash[:shadowy_procs] += 1 if ability_name == 'Shadowy Insight'
    save_cast_detail(event, ability_name, 'buff_on', nil, event['timestamp']) if ability_name == 'Voidform'
  end

  def lose_self_buff_event(event, force=true)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Voidform'
      self.resources_hash[:voidform_uptime] += @cooldowns['Voidform'][:cp].ended_at - @cooldowns['Voidform'][:cp].started_at
      save_cast_detail(event, ability_name, 'buff_off', nil, event['timestamp'])
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::INSANITY
        @insanity = [resource['amount'].to_i - resource['cost'].to_i, 0].max / 100
      end
    end

    if event['resourceChangeType'] == ResourceType::INSANITY
      insanity_waste = [@insanity + event['resourceChange'].to_i - self.max_insanity, 0].max
      insanity_gain = event['resourceChange'].to_i - insanity_waste
      @insanity += insanity_gain
      if @cooldowns['Voidform'][:active] && !@cooldowns['Voidform'][:temp]
        self.resources_hash[:void_insanity_gained] += insanity_gain
        self.resources_hash[:void_insanity_wasted] += insanity_waste
        @cooldowns['Voidform'][:cp].kpi_hash[:insanity_gained] += insanity_gain
        @cooldowns['Voidform'][:cp].kpi_hash[:insanity_wasted] += insanity_waste
        @cooldowns['Voidform'][:cp].kpi_hash[:insanity_abilities][ability_name] ||= {name: ability_name, casts: 0, gain: 0, waste: 0}
        @cooldowns['Voidform'][:cp].kpi_hash[:insanity_abilities][ability_name][:gain] += insanity_gain
        @cooldowns['Voidform'][:cp].kpi_hash[:insanity_abilities][ability_name][:waste] += insanity_waste
        @cooldowns['Voidform'][:cp].kpi_hash[:insanity_abilities][ability_name][:casts] += 1
      else
        self.resources_hash[:insanity_gained] += insanity_gain
        self.resources_hash[:insanity_wasted] += insanity_waste
        self.resources_hash[:insanity_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
        self.resources_hash[:insanity_abilities][ability_name][:gain] += insanity_gain
        self.resources_hash[:insanity_abilities][ability_name][:waste] += insanity_waste
      end
    end
  end

  def clean
    super
    self.resources_hash[:voidray_uptime] = @kpis['Void Ray'].first[:stacks_uptime].to_i unless @kpis['Void Ray'].nil?
    self.debuff_parses.where(name: 'Shadow Word: Pain').each do |debuff|
      self.resources_hash[:pain_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:pain_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.debuff_parses.where(name: 'Vampiric Touch').each do |debuff|
      self.resources_hash[:vampiric_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:vampiric_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.cooldowns_hash[:voidform_damage] = @kpis['Voidform'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:swd_damage] = @kpis['Shadow Word: Death'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:nithramus_damage] = @kpis['Nithramus'].map{|kpi| kpi[:extra_damage].to_i}.sum rescue 0
    self.save
  end

  def calculate_scores
    super
    self.voidform_uptime = (self.resources_hash[:voidform_uptime] / 10) / self.fight_time
  end

end