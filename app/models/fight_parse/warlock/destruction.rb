class FightParse::Warlock::Destruction < FightParse
  include Filterable
  self.table_name = :fp_warlock_destr

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      havoc_missedcasts: [],
    }
    self.resources_hash = {
      immolate_uptime: 0,
      immolate_downtime: 0,
      conflagrate_uptime: 0,
      conflagrate_downtime: 0,
      eradication_uptime: 0,
      havoc_uptime: 0,
      havoc_downtime: 0,
      shadowburn_used: 0,
      shadowburn_killed: 0,
      soul_gain: 0,
      soul_waste: 0,
      soul_abilities: {},
    }
    self.cooldowns_hash = {
      doomguard_damage: 0,
      harvest_damage: 0,
    }
    @resources = {
      "r#{ResourceType::SOULSHARDS}" => 0,
      "r#{ResourceType::SOULSHARDS}_max" => self.max_souls,
    }
    @souls = 1
    @check_abc = true
    self.save
  end

  # settings

  def spell_name(id)
    return {
      18540 => 'Summon Doomguard',
      1122 => 'Summon Infernal',
      348 => 'Immolate',
      157736 => 'Immolate',
      29722 => 'Incinerate',
      17962 => 'Conflagrate',
      116858 => 'Chaos Bolt',
      80240 => 'Havoc',
      29341 => 'Shadowburn',
      111859 => 'Grimoire: Imp',
      196586 => 'Dimensional Rift',
      205184 => 'Roaring Blaze', # 0
      17877 => 'Shadowburn', # 0
      196412 => 'Eradication', # 3
      196414 => 'Eradication',
      108501 => 'Grimoire of Service', #5
      196410 => 'Wreak Havoc', #6
      196447 => 'Channel Demonfire', #6
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Summon Doomguard/Infernal'] = {cd: 180}
    local['Grimoire: Imp'] = {cd: 90} if talent(5) == 'Grimoire: of Service'
    local['Dimensional Rift'] = {cd: 45, extra: 2}
    local['Channel Demonfire'] = {cd: 15} if talent(6) == 'Channel Demonfire'
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    # bars['cd']['Summon Doomguard'] = {cd: 180}
    # bars['cd']['Grimoire: Imp'] = {cd: 90} if talent() == 'Grimoire: Imp'
    return bars
  end

  def debuff_abilities
    local = {
      'Immolate' => {},
      'Havoc' => {},
      'Eradication' => {},
    }
    return super.merge local
  end

  # def cooldown_abilities
  #   local = {
  #     'Dark Soul' => {kpi_hash: {damage_done: 0}},
  #     'Fire and Brimstone' => {kpi_hash: {damage_done: 0}},
  #     'Havoc' => {kpi_hash: {extra_damage: 0}},
  #   }
  #   return super.merge local
  # end

  # def dps_abilities
  #   local = {
  #     'Shadowburn' => {channel: true},
  #     'Immolate (F&B)' => {piggyback: 'Fire and Brimstone'},
  #     'Conflagrate (F&B)' => {piggyback: 'Fire and Brimstone'},
  #     'Incinerate (F&B)' => {piggyback: 'Fire and Brimstone'},
  #     'Chaos Bolt (F&B)' => {piggyback: 'Fire and Brimstone'},
  #   }
  #   return super.merge local
  # end

  # def dps_buff_abilities
  #   local = {
  #     'Dark Soul' => {percent: 1},
  #     'Fire and Brimstone' => {percent: 1},
  #   }
  #   return super.merge local
  # end

  def ticks
    local = {
      42223 => 'Rain of Fire',
    }
    return super.merge local
  end

  def havoc_spells
    [
      'Immolate',
      'Conflagrate',
      'Incinerate',
      'Chaos Bolt', 
      'Shadowburn'
    ]
  end

  def max_souls
    return 5
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def in_progress?
    return true
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ['Summon Doomguard', 'Summon Infernal'].include?(ability_name)
      self.casts_hash['Summon Doomguard/Infernal'] << event['timestamp']
      @casts_details.pop if ['Summon Doomguard', 'Summon Infernal'].include?(@casts_details.last['ability'])
      save_cast_detail(event, 'Summon Doomguard/Infernal', 'cast', "Cast #{ability_name}")
      @cds.delete(ability_name)
      @cds['Summon Doomguard/Infernal'] = (event['timestamp'] + self.track_casts['Summon Doomguard/Infernal'][:cd] * 1000).to_i
    end
    if ability_name == 'Conflagrate' && talent(0) == 'Roaring Blaze'
      if @debuffs['Immolate'].has_key?(target_key) && @debuffs['Immolate'][target_key][:active]
        stacks = @debuffs['Immolate'][target_key][:dp].stacks_array.last[:stacks] + 1
        apply_debuff_stack('Immolate', target_id, event['targetInstance'], event['targetIsFriendly'], stacks, event['timestamp'])
      end
    end
    # lazy way to only catch single target spells
    if havoc_spells.include?(ability_name) && @debuffs['Havoc'].has_key?(target_key) && @debuffs['Havoc'][target_key][:active]
      self.kpi_hash[:havoc_missedcasts] << {timestamp: event['timestamp'], msg: "Cast #{ability_name} on #{@actors[target_id]} with Havoc active."}
    end
    (event['classResources'] || []).each do |resource|
      @souls = [resource['amount'].to_i - resource['cost'].to_i, 0].max if resource['type'] == ResourceType::SOULSHARDS
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::SOULSHARDS
      soul_waste = [@souls + event['resourceChange'].to_i - self.max_souls, 0].max
      soul_gain = event['resourceChange'].to_i - soul_waste
      @souls += soul_gain
      self.resources_hash[:soul_gain] += soul_gain
      self.resources_hash[:soul_waste] += soul_waste
      self.resources_hash[:soul_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:soul_abilities][ability_name][:gain] += soul_gain
      self.resources_hash[:soul_abilities][ability_name][:waste] += soul_waste
      
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"

  end

  def clean
    super
    self.resources_hash[:eradication_uptime] = @uptimes['Eradication'][:uptime]
    self.debuff_parses.where(name: 'Immolate').each do |debuff|
      self.resources_hash[:immolate_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:immolate_downtime] += debuff.kpi_hash[:downtime].to_i
      debuff.kpi_hash[:stacks_uptime] = debuff.stacks_array.map{|stack| stack[:stacks] >= 2 ? (stack[:ended_at] - stack[:started_at]) : 0}.sum
      debuff.save
      self.resources_hash[:conflagrate_uptime] += debuff.kpi_hash[:stacks_uptime].to_i
    end
    self.resources_hash[:conflagrate_downtime] = self.resources_hash[:immolate_uptime].to_i + self.resources_hash[:immolate_downtime].to_i - self.resources_hash[:conflagrate_uptime].to_i
    self.debuff_parses.where(name: 'Immolate').each do |debuff|
      self.resources_hash[:havoc_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:havoc_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.resources_hash[:havoc_downtime] = [self.resources_hash[:havoc_downtime] - self.fight_time * 1000, 0].max
    self.save
  end

end