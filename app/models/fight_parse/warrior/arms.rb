class FightParse::Warrior::Arms < FightParse
  include Filterable
  self.table_name = :fp_warrior_arms

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
      casts_score: 0,
      shattered_defenses_used: 0,
      shattered_defenses_procs: 0,
      shattered_defenses_fails: [],
      colossus_reduction: 0,
      bladestorm_reduction: 0,
      battlecry_reduction: 0,
    }
    self.resources_hash = {
      rage_gain: 0,
      rage_waste: 0,
      rage_abilities: {},
      rage_damage: 0,
      rage_spent: 0,
      rage_spend: {},
      shattered_defenses_uptime: 0,
      good_execute_mortal_strike: 0,
      bad_execute_mortal_strike: 0,
      bad_execute_mortal_strikes: [],
    }
    self.cooldowns_hash = {
      execute_range_damage: 0,
    }
    @resources = {
      "r#{ResourceType::RAGE}" => 0,
      "r#{ResourceType::RAGE}_max" => 160,
    }
    @rage = 0
    @last_colossus = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      167105 => 'Colossus Smash',
      208086 => 'Colossus Smash',
      209574 => 'Shattered Defenses',
      209706 => 'Shattered Defenses',
      248625 => 'Shattered Defenses',
      209577 => 'Warbreaker',
      227847 => 'Bladestorm',
      163201 => 'Execute',
      12294 => 'Mortal Strike',
      772 => 'Rend',
      238147 => 'Executioner\'s Precision',
      242188 => 'Executioner\'s Precision',
      1719 => 'Battle Cry',
      107574 => 'Avatar',
      46924 => 'Bladestorm',
      152277 => 'Ravager',
      199854 => 'Tactician',
      152278 => 'Anger Management',
    }[id] || super(id)
  end

  # SET_IDS = {
  #   20 => [147175, 147176, 147177, 147178, 147179, 147180],
  # }

  def colossus_cd
    return 20
  end

  def track_casts
    local = {}
    local['Avatar'] = {cd: 90} if talent(2) == 'Avatar'
    local['Bladestorm'] = {cd: 90, reduction: self.kpi_hash[:bladestorm_reduction].to_i} if talent(6) != 'Ravager'
    local['Warbreaker'] = {cd: 60}
    local['Ravager'] = {cd: 60, reduction: self.kpi_hash[:bladestorm_reduction].to_i} if talent(6) == 'Ravager'
    local['Battle Cry'] = {cd: 60, reduction: self.kpi_hash[:battlecry_reduction].to_i}
    local['Colossus Smash'] = {cd: self.colossus_cd, reduction: self.kpi_hash[:colossus_reduction].to_i}
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Avatar'] = {cd: 90} if talent(2) == 'Avatar'
    bars['cd']['Bladestorm'] = {cd: 90, reduction: self.kpi_hash[:bladestorm_reduction].to_i} if talent(6) != 'Ravager'
    bars['cd']['Ravager'] = {cd: 60, reduction: self.kpi_hash[:bladestorm_reduction].to_i} if talent(6) == 'Ravager'
    bars['cd']['Battle Cry'] = {cd: 60, reduction: self.kpi_hash[:battlecry_reduction].to_i}
    return bars
  end

  def uptime_abilities
    return {
      'Shattered Defenses' => {},
    }
  end

  def debuff_abilities
    return {
      'Colossus Smash' => {},
      'Rend' => {},
      'Executioner\'s Precision' => {},
      'Execute Range' => {damage_done: 0},
    }
  end

  def cooldown_abilities
    local = {
      'Avatar' => {kpi_hash: {damage_done: 0}},
      'Bladestorm' => {kpi_hash: {damage_done: 0}},
      'Ravager' => {kpi_hash: {damage_done: 0}},
      'Battle Cry' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Avatar' => {percent: 0.2},
      'Battle Cry' => {}
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Bladestorm' => {channel: true},
      'Ravager' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::RAGE]
  end

  def is_execute_range?(event)
    return false if event['targetIsFriendly'] 
    return false if !event.has_key?('hitPoints') && !event.has_key?('maxHitPoints')
    return 100 * event['hitPoints'] / event['maxHitPoints'] <= 20
  end

  # event handlers
  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    target_id = event.has_key?('target') ? event['target']['id'] : event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"

    if @uptimes['Shattered Defenses'][:active] && ['Mortal Strike', 'Execute'].include?(ability_name)
      self.kpi_hash[:shattered_defenses_used] += 1
    end
    if ability_name == 'Colossus Smash'
      @last_colossus = event['timestamp']
    elsif ability_name == 'Mortal Strike'
      if @debuffs.dig('Execute Range', target_key, :active)
        # check for double Executioner's Precision + Shattered Defenses during execute range
        executioner_stacks = @debuffs['Executioner\'s Precision'][target_key][:dp].stacks_array.last[:stacks] rescue 0
        if @uptimes['Shattered Defenses'][:active] && executioner_stacks == 2
          self.resources_hash[:good_execute_mortal_strike] += 1
        else
          self.resources_hash[:bad_execute_mortal_strike] += 1
          self.resources_hash[:bad_execute_mortal_strikes] << {timestamp: event['timestamp'], msg: "Cast Mortal Strike with #{executioner_stacks} stacks of Executioner's Precision #{'and no Shattered Defenses' if !@uptimes['Shattered Defenses'][:active]}"}
        end
      end
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::RAGE
        @rage = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        if resource['cost'].to_i > 0 && talent(6) == 'Anger Management'
          self.kpi_hash[:bladestorm_reduction] += resource['cost'].to_i / 200
          self.kpi_hash[:battlecry_reduction] += resource['cost'].to_i / 200
        end
        # mark rage spent by ability during execute range
        if @debuffs.dig('Execute Range', target_key, :active) && resource['cost'].to_i > 0
          self.resources_hash[:rage_spend][ability_name] ||= {name: ability_name, spent: 0, damage: 0}
          self.resources_hash[:rage_spend][ability_name][:spent] += resource['cost'].to_i / 10
        end
      end
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    target_id = event.has_key?('target') ? event['target']['id'] : event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if is_execute_range?(event) && !event['targetIsFriendly']
      apply_debuff('Execute Range', target_id, event['targetInstance'].to_i, event['targetIsFriendly'], event['timestamp']) unless @debuffs.dig('Execute Range', target_key, :active)
    end
    if @debuffs.dig('Execute Range', target_key, :active)
      # mark damage per rage
      if self.resources_hash[:rage_spend].has_key?(ability_name)
        self.resources_hash[:rage_spend][ability_name][:damage] += event['amount'].to_i
      end
      # mark damage done 
      if event['amount'].to_i > 0
        self.cooldowns_hash[:execute_range_damage] += event['amount'].to_i
        @debuffs['Execute Range'][target_key][:dp].kpi_hash[:damage_done] += event['amount'].to_i
        @debuffs['Execute Range'][target_key][:dp].details_hash[event['ability']['guid']] ||= {name: ability_name, damage: 0, hits: 0}
        @debuffs['Execute Range'][target_key][:dp].details_hash[event['ability']['guid']][:damage] += event['amount'].to_i
        @debuffs['Execute Range'][target_key][:dp].details_hash[event['ability']['guid']][:hits] += 1
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Shattered Defenses'
      self.kpi_hash[:shattered_defenses_procs] += 1 
      if refresh
        self.kpi_hash[:shattered_defenses_fails] << {timestamp: event['timestamp'], msg: "Shattered Defenses proc refreshed."}
      end
    elsif ability_name == 'Tactician' && !@last_colossus.nil?
      cd_reduction = [@last_colossus + (self.colossus_cd * 1000) - event['timestamp'], 0].max
      if cd_reduction > 0
        self.kpi_hash[:colossus_reduction] += (cd_reduction / 1000)
        save_cast_detail(event, 'Colossus Smash', 'off_cd', 'Colossus Smash cooldown reset by Tactician')
        @last_colossus = nil
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::RAGE && event['resourceChange'].to_i > 0
      rage_waste = event['waste'].to_i
      rage_gain = event['resourceChange'].to_i - rage_waste
      @rage += rage_gain
      self.resources_hash[:rage_gain] += rage_gain
      self.resources_hash[:rage_waste] += rage_waste
      self.resources_hash[:rage_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:rage_abilities][ability_name][:gain] += rage_gain
      self.resources_hash[:rage_abilities][ability_name][:waste] += rage_waste
    end
  end

  def clean
    super
    aggregate_dps_cooldowns
    aggregate_debuffs
    self.resources_hash[:rage_spend].each do |key, spell|
      self.resources_hash[:rage_damage] += spell[:damage].to_i
      self.resources_hash[:rage_spent] += spell[:spent].to_i
    end
    self.save
  end
end