class FightParse::Warlock::Affliction < FightParse
  include Filterable
  self.table_name = :fp_warlock_aff

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def in_progress?
    return true
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
    }
    self.resources_hash = {
      soulshard_gain: 0,
      soulshard_waste: 0,
      soulshard_abilities: {},
    }
    self.cooldowns_hash = {

    }
    @resources = {
      "r#{ResourceType::SOULSHARDS}" => 0,
      "r#{ResourceType::SOULSHARDS}_max" => self.max_souls,
    }
    @souls = 1
    @casting_drain = false
    @check_abc = true
    self.save
  end

  # settings

  def spell_name(id)
    return {
      980 => 'Agony',
      172 => 'Corruption',
      146739 => 'Corruption',
      30108 => 'Unstable Affliction',
      233490 => 'Unstable Affliction',
      233496 => 'Unstable Affliction',
      233497 => 'Unstable Affliction',
      233498 => 'Unstable Affliction',
      233499 => 'Unstable Affliction',
      198590 => 'Drain Soul',
      216698 => 'Reap Souls',
      216695 => 'Tormented Souls',
      235155 => 'Malefic Grasp', #0
      196098 => 'Soul Harvest', #3
    }[id] || super(id)
  end

  def channel_abilities
    return super + [
      'Drain Soul',
    ]
  end

  def track_casts
    local = {
      'Soul Harvest' => {cd: 120}
    }

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Soul Harvest'] = {cd: 120} if talent(3) == 'Soul Harvest'
    bars['cd']['Tormented Souls'] = {}
    return bars
  end

  def debuff_abilities
    local = {
      'Agony' => {},
      'Corruption' => {single_target: true},
      'Unstable Affliction' => {target_stacks: 2},
      'Drain Soul' => {drain_soul_uptime: 0},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Tormented Souls' => {kpi_hash: {damage_done: 0}},
      'Soul Harvest' => {kpi_hash: {damage_done: 0}},
      'Unstable Affliction' => {kpi_hash: {damage_done: 0, drain_soul_uptime: 0}},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Tormented Souls' => {percent: 1},
      'Soul Harvest' => {percent: 0.2},
    }
    return super.merge local
  end

  def max_souls
    return 5
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    (event['classResources'] || []).each do |resource|
      @souls = [resource['amount'].to_i - resource['cost'].to_i, 0].max if resource['type'] == ResourceType::SOULSHARDS
      # for some reason the cost is in fractions of soul shards
      @souls = @souls / 10 if @souls > self.max_souls
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::SOULSHARDS
      soulshard_waste = [@souls + event['resourceChange'].to_i - self.max_souls, 0].max
      soulshard_gain = event['resourceChange'].to_i - soulshard_waste
      @souls += soulshard_gain
      self.resources_hash[:soulshard_gain] += soulshard_gain
      self.resources_hash[:soulshard_waste] += soulshard_waste
      self.resources_hash[:soulshard_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:soulshard_abilities][ability_name][:gain] += soulshard_gain
      self.resources_hash[:soulshard_abilities][ability_name][:waste] += soulshard_waste
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Unstable Affliction'
      target_id = event.has_key?('target') ? event['target']['id'] : event['targetID']
      target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
      amount = event['amount'].to_i
      @cooldowns[ability_name][:cp].kpi_hash[:damage_done] = @cooldowns[ability_name][:cp].kpi_hash[:damage_done].to_i + amount
      @cooldowns[ability_name][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
      @cooldowns[ability_name][:cp].details_hash[target_key][:damage] += amount
      @cooldowns[ability_name][:cp].details_hash[target_key][:hits] += 1
      @cooldowns[ability_name][:cp].ended_at = event['timestamp']
      @cooldowns[ability_name][:cp].save if !@cooldowns[ability_name][:active] && !@cooldowns[ability_name][:temp]
      @cooldowns[ability_name][:temp] = false
    end
  end

  def apply_debuff_event(event, refresh=false)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Unstable Affliction'
      # manually track stacks, since each application has a different spell ID
      event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
      target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
      event['stack'] = @debuffs['Unstable Affliction'][target_key][:dp].stacks_array.last[:stacks].to_i + 1 rescue 1
      apply_debuff_stack_event(event)
      gain_cooldown(ability_name, event['timestamp'], {drain_soul_uptime: 0}) if event['stack'] == 1
    else
      if ability_name == 'Drain Soul' && @debuffs['Unstable Affliction'].has_key?(target_key) && @debuffs['Unstable Affliction'][target_key][:active]
        @cooldowns['Unstable Affliction'][:cp].kpi_hash[:drain_soul_uptime] -= event['timestamp']
      end
      super
    end
  end

  def remove_debuff_event(event, refresh=false)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Unstable Affliction'
      # manually track stacks, since each application has a different spell ID
      event['stack'] = @debuffs['Unstable Affliction'][target_key][:dp].stacks_array.last[:stacks].to_i - 1 rescue 0
      if event['stack'] > 0
        remove_debuff_stack_event(event)
      else
        super
        if @debuffs['Drain Soul'][target_key][:active]
          @cooldowns['Unstable Affliction'][:cp].kpi_hash[:drain_soul_uptime] += event['timestamp']
        end
        @cooldowns['Unstable Affliction'][:cp].kpi_hash[:active_time] = event['timestamp'] - @cooldowns['Unstable Affliction'][:cp].started_at
        drop_cooldown(ability_name, event['timestamp'])
      end
    else
      if ability_name == 'Drain Soul' && @debuffs.dig('Unstable Affliction', target_key, :active) && @cooldowns['Unstable Affliction'][:cp].kpi_hash[:drain_soul_uptime] < 0
        @cooldowns['Unstable Affliction'][:cp].kpi_hash[:drain_soul_uptime] += event['timestamp']
      end
      super
    end
  end

  def clean
    super
    aggregate_dps_cooldowns
    aggregate_debuffs
    self.cooldowns_hash[:unstable_affliction_damage] = @kpis['Unstable Affliction'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:unstable_affliction_active_time] = @kpis['Unstable Affliction'].map{|kpi| kpi[:active_time].to_i}.sum rescue 0
    self.cooldowns_hash[:drain_soul_during_ua] = @kpis['Unstable Affliction'].map{|kpi| kpi[:drain_soul_uptime].to_i}.sum rescue 0
    self.save
  end

end