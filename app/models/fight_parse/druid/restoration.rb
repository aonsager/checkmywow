class FightParse::Druid::Restoration < HealerParse
  include Filterable
  self.table_name = :fp_druid_resto

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 3
  end

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
      mastery_healing_increase: 0,
      mastery_overhealing_increase: 0,
      mastery_stacks: {
        1 => {healing_increase: 0, overhealing_increase: 0},
        2 => {healing_increase: 0, overhealing_increase: 0},
        3 => {healing_increase: 0, overhealing_increase: 0},
        4 => {healing_increase: 0, overhealing_increase: 0},
        5 => {healing_increase: 0, overhealing_increase: 0},
      },
    }
    self.resources_hash = {
      mana_spent: 0,
      heal_per_mana: {},
      soul_procs: 0,
      soul_uses: 0,
      soul_abilities: {},
      good_regrowths: 0,
      bad_regrowths: 0,
      regrowth_fails: [],

    }
    self.cooldowns_hash = {
      incarnation_healing: 0,
      incarnation_overhealing: 0,
    }
    @check_abc = true
    @eff_id = 0
    
    @temp_pet = CooldownParse.new(fight_parse_id: self.id, cd_type: 'pet', name: 'Efflorescence', kpi_hash: {healing_done: 0, overhealing_done: 0}, started_at: self.started_at)
    @drop_clearcasting
    self.save
    @active_hots = {}
  end

  # settings

  def uptime_abilities
    local = {
      'Soul of the Forest' => {},
      'Clearcasting' => {},
    }
    return super.merge local
  end

  def track_casts
    local = {}
    local['Innervate'] = {cd: 180}
    local['Incarnation: Tree of Life'] = {cd: 180} if talent(4) == 'Incarnation: Tree of Life'
    local['Tranquility'] = {cd: (talent(5) == 'Inner Peace' ? 120 : 180)}
    local['Essence of G\'Hanir'] = {cd: 90}
    local['Ironbark'] = {cd: (talent(6) == 'Stonebark' ? 60 : 90)}
    local['Cenarion Ward'] = {cd: 30} if talent(0) == 'Cenarion Ward'
    if talent(4) == 'Soul of the Forest'
      if talent(0) == 'Prosperity'
        local['Swiftmend'] = {cd: 25, extra: 1}
      else
        local['Swiftmend'] = {cd: 30}
      end
    end

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Incarnation: Tree of Life'] = {cd: 180} if talent(4) == 'Incarnation: Tree of Life'
    bars['cd']['Tranquility'] = {cd: (talent(5) == 'Inner Peace' ? 120 : 180)}
    bars['cd']['Ironbark'] = {cd: (talent(6) == 'Stonebark' ? 60 : 90)}
    
    return bars
  end

  def healing_abilities
    local = [
      'Tranquility',
      'Wild Growth',
    ]
    return super + local
  end

  def healing_buff_abilities
    local = {
      'Incarnation: Tree of Life' => {percent: 0.15},
      'Essence of G\'Hanir' => {percent: 1, only_tick: true},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Tranquility' => {kpi_hash: {healing_done: 0, overhealing_done: 0}},
      'Wild Growth' => {kpi_hash: {healing_done: 0, overhealing_done: 0}},
      'Incarnation: Tree of Life' => {kpi_hash: {healing_done: 0, overhealing_done: 0}},
      'Essence of G\'Hanir' => {kpi_hash: {healing_done: 0, overhealing_done: 0}},
    }
    return super.merge local
  end

  def external_buff_abilities
    local = {
      'Lifebloom' => {},
      'Rejuvenation' => {},
      'Wild Growth' => {},
      'Regrowth' => {},
      'Spring Blossoms' => {},
      'Living Seed' => {},
      'Mastery: Harmony' => {target_stacks: 3},
      'Cultivation' => {},
      'Ironbark' => {},
      'Stonebark' => {},
    }
    return super.merge local
  end

  def ticks
    local = {
      157982 => 'Tranquility',
    }
    return super.merge local
  end

  def show_resources
    return [ResourceType::MANA]
  end

  def ghanir_length
    return 8000
  end

  def mastery_increase(stacks)
    return (100 + self.mastery_percent * stacks) / 100.0
  end

  # getters

  def spell_name(id)
    return {
      188550 => 'Lifebloom',
      33763 => 'Lifebloom',
      774 => 'Rejuvenation',
      145205 => 'Efflorescence',
      48438 => 'Wild Growth',
      8936 => 'Regrowth',
      18562 => 'Swiftmend',
      16870 => 'Clearcasting',
      740 => 'Tranquility',
      157982 => 'Tranquility',
      29166 => 'Innervate',
      102342 => 'Ironbark',
      22812 => 'Barkskin',
      200383 => 'Prosperity',
      102351 => 'Cenarion Ward',
      33891 => 'Incarnation: Tree of Life',
      200389 => 'Cultivation',
      200390 => 'Cultivation',
      197073 => 'Inner Peace',
      197061 => 'Stonebark',
      158478 => 'Soul of the Forest',
      114108 => 'Soul of the Forest',
      207385 => 'Spring Blossoms',
      48504 => 'Living Seed',
      197721 => 'Flourish',
      208253 => 'Essence of G\'Hanir',
    }[id] || super(id)
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if @uptimes['Soul of the Forest'][:active] && ['Regrowth', 'Rejuvenation', 'Wild Growth'].include?(ability_name)
      self.resources_hash[:soul_uses] += 1
      self.resources_hash[:soul_abilities][ability_name] ||= {name: ability_name, casts: 0}
      self.resources_hash[:soul_abilities][ability_name][:casts] += 1
    end
    if ability_name == 'Regrowth'
      if (@uptimes['Clearcasting'][:active] || @drop_clearcasting == event['timestamp'])
        self.resources_hash[:good_regrowths] += 1
      else
        self.resources_hash[:bad_regrowths] += 1
        self.resources_hash[:regrowth_fails] << {timestamp: event['timestamp'], msg: 'Cast Regrowth without a Clearcasting proc'}
      end
    end
  end

  def summon_pet_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    @eff_id = target_id if ability_name == 'Efflorescence'
  end

  def pet_death(id, timestamp)
    if !@pets.has_key?(id)
      # pet was probably summoned before the fight began
      if @actors[id] == 'Efflorescence'
        @pets[id] ||= {active: false, pet: @temp_pet}
      end
    end
    super
  end

  def heal_event(event)
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if is_active?('Essence of G\'Hanir', event['timestamp']) && event['timestamp'] > @cooldowns['Essence of G\'Hanir'][:cp].started_at + ghanir_length
      drop_cooldown('Essence of G\'Hanir', @cooldowns['Essence of G\'Hanir'][:cp].started_at + ghanir_length)
    end

    super
    
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id}-#{event['targetInstance']}"
    return unless @player_ids.include?(target_id)
    if ability_name == 'Efflorescence'
      @eff_id == 0 ? pet = @temp_pet : pet = @pets[@eff_id][:pet]
      pet.kpi_hash[:healing_done] = pet.kpi_hash[:healing_done].to_i + event['amount'].to_i
      pet.kpi_hash[:overhealing_done] = pet.kpi_hash[:overhealing_done].to_i + event['overheal'].to_i
    end

    # check for mastery stacks
    if !@active_hots[target_key].nil? && @active_hots[target_key].count > 0
      stacks = @active_hots[target_key].count
      healing_increase = event['amount'].to_i - (event['amount'].to_i / mastery_increase(stacks)).to_i
      overhealing_increase = event['overheal'].to_i - (event['overheal'].to_i / mastery_increase(stacks)).to_i
      self.kpi_hash[:mastery_healing_increase] += healing_increase
      self.kpi_hash[:mastery_overhealing_increase] += overhealing_increase
      self.kpi_hash[:mastery_stacks][stacks] ||= {healing_increase: 0, overhealing_increase: 0}
      self.kpi_hash[:mastery_stacks][stacks][:healing_increase] += healing_increase
      self.kpi_hash[:mastery_stacks][stacks][:overhealing_increase] += overhealing_increase
    end

  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:soul_procs] += 1 if ability_name == 'Soul of the Forest'
    if ability_name == 'Clearcasting' && refresh
      self.resources_hash[:bad_regrowths] += 1
      self.resources_hash[:regrowth_fails] << {timestamp: event['timestamp'], msg: 'Refreshed Clearcasting proc before using'}
    end
  end

  def lose_self_buff_event(event, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    @drop_clearcasting = event['timestamp'] if ability_name == 'Clearcasting'
  end

  def apply_external_buff_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id}-#{event['targetInstance']}"
    return unless @player_ids.include?(target_id)
    if external_buff_abilities.include?(ability_name)
      @active_hots[target_key] ||= []
      @active_hots[target_key] << ability_name unless @active_hots[target_key].include?(ability_name)
      stacks = [@active_hots[target_key].count, 3].min
      apply_external_buff_stack('Mastery: Harmony', target_id, event['targetInstance'], stacks, event['timestamp'])
    end
  end

  def drop_external_buff_event(event, refresh=false, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id}-#{event['targetInstance']}"
    return unless @player_ids.include?(target_id)
    if external_buff_abilities.include?(ability_name)
      @active_hots[target_key] ||= []
      @active_hots[target_key].delete(ability_name)
      stacks = [@active_hots[target_key].count, 3].min
      if stacks > 0
        remove_external_buff_stack('Mastery: Harmony', target_id, event['targetInstance'], stacks, event['timestamp'])
      else
        remove_external_buff('Mastery: Harmony', target_id, event['targetInstance'], event['timestamp'])
      end
    end
  end

  # setters

  def clean
    super
    self.resources_hash[:lifebloom_uptime] = @uptimes['Lifebloom'][:uptime]
    self.resources_hash[:rejuvenation_uptime] = @uptimes['Rejuvenation'][:uptime]
    self.resources_hash[:mastery_uptime] = @external_buffs['Mastery: Harmony'].map{|key, hash| hash[:bp].kpi_hash[:stacks_uptime].to_i}.sum
    log(@kpis.keys)
    log(@kpis['Wild Growth'])
    self.cooldowns_hash[:wildgrowth_healing] = @kpis['Wild Growth'].map{|kpi| kpi[:healing_done].to_i}.sum rescue 0
    self.cooldowns_hash[:wildgrowth_overhealing] = @kpis['Wild Growth'].map{|kpi| kpi[:overhealing_done].to_i}.sum rescue 0
    self.cooldowns_hash[:tranquility_healing] = @kpis['Tranquility'].map{|kpi| kpi[:healing_done].to_i}.sum rescue 0
    self.cooldowns_hash[:tranquility_overhealing] = @kpis['Tranquility'].map{|kpi| kpi[:overhealing_done].to_i}.sum rescue 0
    self.cooldowns_hash[:ghanir_healing] = @kpis['Essence of G\'Hanir'].map{|kpi| kpi[:healing_increase].to_i}.sum rescue 0
    self.cooldowns_hash[:ghanir_overhealing] = @kpis['Essence of G\'Hanir'].map{|kpi| kpi[:overhealing_increase].to_i}.sum rescue 0
    self.cooldowns_hash[:incarnation_healing] = @kpis['Incarnation: Tree of Life'].map{|kpi| kpi[:healing_increase].to_i}.sum rescue 0
    self.cooldowns_hash[:incarnation_overhealing] = @kpis['Incarnation: Tree of Life'].map{|kpi| kpi[:overhealing_increase].to_i}.sum rescue 0

    self.save
  end

end