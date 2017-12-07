class FightParse::Monk::Mistweaver < HealerParse
  include Filterable
  self.table_name = :fp_monk_mist

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
      trance_procs: 0,
      trance_used: 0,
      trance_details: [],
      thunder_used: 0,
      thunder_abilities: {},
      mana_tea_saved: 0,
      monastery_bok: {0=>0, 1=>0, 2=>0, 3=>0},
      lifecycles_enveloping_procs: 0,
      lifecycles_vivify_procs: 0,
      lifecycles_enveloping_uses: 0,
      lifecycles_vivify_uses: 0,
    }
    self.cooldowns_hash = {
      enveloping_healing: 0,
      enveloping_healing_increased: 0,
      enveloping_overhealing: 0,
      cocoon_absorb: 0,
      cocoon_healing: 0,
      cocoon_overhealing: 0,
      essence_healing: 0,
      essence_overhealing: 0,
      essence_mastery_healing: 0,
      essence_mastery_overhealing: 0,
      revival_healing: 0,
      revival_overhealing: 0,
      rjw_healing: 0,
      rjw_overhealing: 0,
      chiji_healing: 0,
      chiji_overhealing: 0,
      sheilun_healing: 0,
      sheilun_overhealing: 0,
    }
    self.save
    @check_abc = true
    @last_cast
    @trance = false
  end

  # settings

  def uptime_abilities
    local = {
      'Uplifting Trance' => {},
      'Thunder Focus Tea' => {},
      'Lifecycles (Enveloping Mist)' => {},
      'Lifecycles (Vivify)' => {},
    }
    return super.merge local
  end

  def track_casts
    local = {}
    local['Revival'] = {cd: 180}
    local['Life Cocoon'] = {cd: 180}
    local['Invoke Chi-Ji, the Red Crane'] = {cd: 180} if talent(5) == 'Invoke Chi-Ji, the Red Crane'
    local['Mana Tea'] = {cd: 90} if talent(6) == 'Mana Tea'
    local['Renewing Mist'] = {cd: 8}
    if talent(6) == 'Rising Thunder'
      local['Rising Sun Kick'] = {cd: 8}
      local['Thunder Focus Tea'] = {cd: 30, extra: (self.casts_hash['Rising Sun Kick'].size rescue 0)}
    else
      local['Thunder Focus Tea'] = {cd: 30}
    end
    local['Chi Burst'] = {cd: 30} if talent(0) == 'Chi Burst'
    local['Zen Pulse'] = {cd: 15} if talent(0) == 'Zen Pulse'

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['external_absorb']['Life Cocoon'] = {cd: 180}
    bars['heal']['Revival'] = {cd: 180}
    bars['heal']['Essence Font'] = {}
    bars['heal']['Refreshing Jade Wind'] = {}

    return bars
  end

  def healing_abilities
    local = [
      'Revival',
      'Essence Font',
      'Refreshing Jade Wind',
      'Sheilun\'s Gift',
    ]
    return super + local
  end

  def external_healing_abilities
    local = [
      'Enveloping Mist',
    ]
    return super + local
  end

  def absorbing_abilities
    local = [
      'Life Cocoon'
    ]
    return super + local
  end

  def external_healing_buff_abilities
    local = {
      'Life Cocoon' => {percent: 0.5},
      'Enveloping Mist' => {percent: 0.3},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Mana Tea' => {kpi_hash: {mana_reduced: 0}},
      # 'Enveloping Mist' => {kpi_hash: {healing_done: 0, overhealing_done: 0, healing_increase: 0}},
      # 'Life Cocoon' => {kpi_hash: {healing_done: 0, overhealing_done: 0, healing_increase: 0}},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Teachings of the Monastery' => {},
      'The Mists of Sheilun' => {},
    }
    return super.merge local
  end

  def external_buff_abilities
    local = {
      'Renewing Mist' => {},
      'Essence Font' => {},
    }
    return super.merge local
  end

  def ticks
    local = {
      162530 => 'Refreshing Jade Wind',
    }
    return super.merge local
  end

  def show_resources
    return [ResourceType::MANA]
  end

  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  # getters

  def spell_name(id)
    return {
      115151 => 'Renewing Mist',
      119611 => 'Renewing Mist',
      197206 => 'Uplifting Trance',
      116670 => 'Vivify',
      124682 => 'Enveloping Mist',
      116694 => 'Effuse',
      191837 => 'Essence Font',
      191840 => 'Essence Font',
      116849 => 'Life Cocoon',
      115310 => 'Revival',
      116680 => 'Thunder Focus Tea',
      191894 => 'Mastery: Gusts of Mists',
      123986 => 'Chi Burst',
      124081 => 'Zen Pulse',
      197915 => 'Lifecycles',
      210802 => 'Spirit of the Crane',
      162530 => 'Refreshing Jade Wind',
      196725 => 'Refreshing Jade Wind',
      198664 => 'Invoke Chi-Ji, the Red Crane',
      197908 => 'Mana Tea',
      197895 => 'Focused Thunder',
      210804 => 'Rising Thunder',
      100780 => 'Tiger Palm',
      100784 => 'Blackout Kick',
      107428 => 'Rising Sun Kick',
      116645 => 'Teachings of the Monastery',
      202090 => 'Teachings of the Monastery',
      197919 => 'Lifecycles (Enveloping Mist)',
      197916 => 'Lifecycles (Vivify)',
      199894 => 'The Mists of Sheilun',
      199888 => 'The Mists of Sheilun',
      205406 => 'Sheilun\'s Gift',
    }[id] || super(id)
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if @uptimes['Uplifting Trance'][:active] && ability_name == 'Vivify'
      self.resources_hash[:trance_used] += 1 
      @trance = true
    elsif @uptimes['Thunder Focus Tea'][:active] && ['Renewing Mist', 'Effuse', 'Enveloping Mist', 'Essence Font', 'Vivify'].include?(ability_name)
      self.resources_hash[:thunder_abilities][ability_name] = self.resources_hash[:thunder_abilities][ability_name].to_i + 1
    elsif ability_name == 'Blackout Kick'
      stacks = @buffs['Teachings of the Monastery'][:bp].stacks_array.last[:stacks] rescue 0
      self.resources_hash[:monastery_bok][stacks] = self.resources_hash[:monastery_bok][stacks].to_i + 1
    elsif ability_name == 'Enveloping Mist' && @uptimes['Lifecycles (Enveloping Mist)'][:active]
      self.resources_hash[:lifecycles_enveloping_uses] += 1
    elsif ability_name == 'Vivify' && @uptimes['Lifecycles (Vivify)'][:active]
      self.resources_hash[:lifecycles_vivify_uses] += 1
    end
    if @cooldowns['Mana Tea'][:active]
      (event['classResources'] || []).each do |resource|
        if resource['type'] == ResourceType::MANA && resource['cost'].to_i > 0
          @cooldowns['Mana Tea'][:cp].kpi_hash[:mana_reduced] += resource['cost'].to_i
          @cooldowns['Mana Tea'][:cp].details_hash[ability_name] ||= {name: ability_name, mana_reduced: 0, casts: 0}
          @cooldowns['Mana Tea'][:cp].details_hash[ability_name][:mana_reduced] += resource['cost'].to_i
          @cooldowns['Mana Tea'][:cp].details_hash[ability_name][:casts] += 1
        end
      end
    end
    # handle RJW manually here, since all ticks have the same guid
    if ability_name == 'Refreshing Jade Wind'
      # don't make a new object if we're still within the 6 second channel time
      if !@cooldowns.has_key?('Refreshing Jade Wind') || !@cooldowns['Refreshing Jade Wind'][:active] || event['timestamp'] - 6000 > @cooldowns['Refreshing Jade Wind'][:cp].started_at 
        if @cooldowns.has_key?('Refreshing Jade Wind') && @cooldowns['Refreshing Jade Wind'][:active]
          drop_cooldown('Refreshing Jade Wind', @cooldowns['Refreshing Jade Wind'][:cp].started_at + 6000, 'heal', true)
        end

        # set up an object to catch heals done by this ability
        if @cooldowns[ability_name][:casting]
          @cooldowns[ability_name][:active] = true
          @cooldowns[ability_name][:casting] = false
        else
          gain_cooldown(ability_name, event['timestamp'], {healing_done: 0, overhealing_done: 0}, 'heal')
          @cooldowns[ability_name][:active] = true
        end
      end
    end
    # track base cast of mastery heals
    @last_cast = ability_name if ['Renewing Mist', 'Enveloping Mist', 'Effuse', 'Vivify'].include?(ability_name) 
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.resources_hash[:trance_procs] += 1 if ability_name == 'Uplifting Trance'
    self.resources_hash[:thunder_used] += 1 if ability_name == 'Thunder Focus Tea'
    self.resources_hash[:lifecycles_vivify_procs] += 1 if ability_name == 'Lifecycles (Vivify)'
    self.resources_hash[:lifecycles_enveloping_procs] += 1 if ability_name == 'Lifecycles (Enveloping Mist)'
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return unless @player_ids.include?(target_id)
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if @trance && ability_name == 'Vivify'
      self.resources_hash[:trance_details] << {timestamp: event['timestamp'], heal: event['amount'].to_i, overheal: event['overheal'].to_i}
      @trance = false
    end
    if @external_buffs['Essence Font'].has_key?(target_key) && ability_name == 'Mastery: Gusts of Mists'
      @cooldowns['Essence Font'][:cp].kpi_hash[:mastery_healing] = @cooldowns['Essence Font'][:cp].kpi_hash[:mastery_healing].to_i + event['amount'].to_i
      @cooldowns['Essence Font'][:cp].kpi_hash[:mastery_overhealing] = @cooldowns['Essence Font'][:cp].kpi_hash[:mastery_overhealing].to_i + event['overheal'].to_i
      @cooldowns['Essence Font'][:cp].details_hash[@last_cast] ||= {name: @last_cast, casts: 0, mastery_healing: 0, mastery_overhealing: 0}
      @cooldowns['Essence Font'][:cp].details_hash[@last_cast][:casts] += 1
      @cooldowns['Essence Font'][:cp].details_hash[@last_cast][:mastery_healing] += event['amount'].to_i
      @cooldowns['Essence Font'][:cp].details_hash[@last_cast][:mastery_overhealing] += event['overheal'].to_i
      # @cooldowns['Essence Font'][:cp].save if !@cooldowns['Essence Font'][:active]
    end
  end

  # setters

  def clean
    super
    
    score = max_score = 0
    max_score += casts_possible(track_casts['Renewing Mist']).to_i * track_casts['Renewing Mist'][:cd].to_i
    score += [self.casts_hash['Renewing Mist'].size * track_casts['Renewing Mist'][:cd].to_i, max_score].min
    max_score += casts_possible(track_casts['Thunder Focus Tea']).to_i * track_casts['Thunder Focus Tea'][:cd].to_i
    score += [self.casts_hash['Thunder Focus Tea'].size * track_casts['Thunder Focus Tea'][:cd].to_i, max_score].min
    max_score = score if score > max_score
    self.kpi_hash[:casts_score] = [100, 100 * score / max_score].min rescue 0

    self.resources_hash[:mana_tea_saved] = @kpis['Mana Tea'].map{|kpi| kpi[:mana_reduced].to_i}.sum rescue 0
    self.resources_hash[:renewingmist_uptime] = @uptimes['Renewing Mist'][:uptime]
    self.cooldowns_hash[:enveloping_healing] = @kpis['Enveloping Mist'].map{|kpi| kpi[:healing_done].to_i}.sum rescue 0
    self.cooldowns_hash[:enveloping_healing_increased] = @kpis['Enveloping Mist'].map{|kpi| kpi[:healing_increased].to_i}.sum rescue 0
    self.cooldowns_hash[:enveloping_overhealing] = @kpis['Enveloping Mist'].map{|kpi| kpi[:overhealing_done].to_i + kpi[:overhealing_increased].to_i}.sum rescue 0
    self.cooldowns_hash[:cocoon_absorb] = @kpis['Life Cocoon'].map{|kpi| kpi[:absorbing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:cocoon_healing] = @kpis['Life Cocoon'].map{|kpi| kpi[:healing_increased].to_i }.sum rescue 0
    self.cooldowns_hash[:cocoon_overhealing] = @kpis['Life Cocoon'].map{|kpi| kpi[:overhealing_increased].to_i + kpi[:leftover_absorb].to_i}.sum rescue 0
    self.cooldowns_hash[:essence_healing] = @kpis['Essence Font'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:essence_overhealing] = @kpis['Essence Font'].map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:essence_mastery_healing] = @kpis['Essence Font'].map{|kpi| kpi[:mastery_healing].to_i }.sum rescue 0
    self.cooldowns_hash[:essence_mastery_overhealing] = @kpis['Essence Font'].map{|kpi| kpi[:mastery_overhealing].to_i }.sum rescue 0
    self.cooldowns_hash[:revival_healing] = @kpis['Revival'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:revival_overhealing] = @kpis['Revival'].map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:rjw_healing] = @kpis['Refreshing Jade Wind'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:rjw_overhealing] = @kpis['Refreshing Jade Wind'].map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:sheilun_healing] = @kpis['Sheilun\'s Gift'].map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
    self.cooldowns_hash[:sheilun_overhealing] = @kpis['Sheilun\'s Gift'].map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
    @pet_kpis.each do |pet_name, kpis|
      if pet_name == 'Chi-Ji'
        self.cooldowns_hash[:chiji_healing] = kpis.map{|kpi| kpi[:healing_done].to_i }.sum rescue 0
        self.cooldowns_hash[:chiji_overhealing] = kpis.map{|kpi| kpi[:overhealing_done].to_i }.sum rescue 0
      end
    end
    self.save
  end

end