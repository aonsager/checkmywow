class HealerParse < FightParse

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
    }
    (self.healing_buff_abilities.keys + self.healing_abilities + self.damage_reduction_cooldowns.keys).uniq.each do |name| 
      CooldownParse.find_by_id(@cooldowns[name][:cp].id).try(:destroy) unless @cooldowns[name].nil? || @cooldowns[name][:cp].nil?
      @cooldowns[name] = {active: false, buffer: 0, cp: nil}
    end
    @low_hps = {}
    self.version = self.class.latest_version
    self.save
  end

  # settings

  def self.score_categories
    return {
      'casts_score' => 'Casts',
    }
  end

  def procs
    local = {
      'Etheralus' => {cd: 120},
    }
    return super.merge local
  end

  # track healing done while abilities are active. uses kpi_hash[:healing_done]
  def healing_buff_abilities
    return {
      'Etheralus' => {},
    }
  end

  # healing buffs that we want to track on other players
  def external_healing_buff_abilities
    return {}
  end

  def healing_abilities
    return []
  end

  def external_healing_abilities
    return []
  end

  # abilities to be ignored by healing_buff tracking
  def healing_ignore_abilities
    return [
      'Etheralus',
    ]
  end

  # damage-reduction buffs that we want to track
  def damage_reduction_cooldowns
    return {}
  end

  # damage-reduction buffs that we want to track on other players
  def external_damage_reduction_cooldowns
    return {}
  end

  def absorbing_abilities
    return []
  end

  def self.latest_version
    return super * 1000 + 2
  end

  # getters

  def max_basic_bar
    return [
      (self.kpi_hash[:healing_done] + self.kpi_hash[:overhealing_done]),
      (self.kpi_hash[:absorbing_done] + self.kpi_hash[:leftover_absorb]),
    ].max
  end

  def cooldown_timeline_bars
    bars = super
    bars['heal'] = {}
    return bars
  end

  def hp_event_s(event)
    if event[:type] == 'damage'
      "[#{event_time(event[:timestamp], true)}] #{event[:source]}'s #{event[:name]} deals <span class='red'>#{event[:amount]}</span> damage (<span class='red'>#{event[:hp]}% HP</span>)"
    elsif event[:type] == 'heal'
      "[#{event_time(event[:timestamp], true)}] <span class='#{event[:source] == self.player_name ? 'green' : ''}'>#{event[:source]}'s #{event[:name]}</span> heals for <span class='green'>#{event[:amount]}</span> (<span class='green'>#{event[:hp]}% HP</span>)"
    elsif event[:type] == 'absorb'
      "[#{event_time(event[:timestamp], true)}] <span class='#{event[:source] == self.player_name ? 'green' : ''}'>#{event[:source]}'s #{event[:name]}</span> absorbs <span class='green'>#{event[:amount]}</span> damage (<span class='green'>#{event[:hp]}% HP</span>)"
    elsif event[:type] == 'death'
      "[#{event_time(event[:timestamp], true)}] <span class='red'>Death</span>"
    end
  end

  # event handlers

  def begin_cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if self.healing_abilities.include? ability_name
      if @cooldowns.has_key?(ability_name) && @cooldowns[ability_name][:active]
        ended_at = @cooldowns[ability_name][:cp].ended_at || @cooldowns[ability_name][:cp].started_at
        drop_cooldown(ability_name, ended_at, 'heal', true)
      end
      # set up an object to catch heals done by this ability
      gain_cooldown(ability_name, event['timestamp'], {healing_done: 0, overhealing_done: 0}, 'heal')
      @cooldowns[ability_name][:active] = false
      @cooldowns[ability_name][:casting] = true
    end
    if self.damage_reduction_cooldowns.keys.include? ability_name
      # set up an object to catch damage reduced by this ability
      if @cooldowns.has_key?(ability_name) && @cooldowns[ability_name][:active]
        ended_at = @cooldowns[ability_name][:cp].ended_at || @cooldowns[ability_name][:cp].started_at
        drop_cooldown(ability_name, ended_at, nil, true)
      end
      gain_cooldown(ability_name, event['timestamp'], {damage_reduced: 0})
      @cooldowns[ability_name][:active] = false
      @cooldowns[ability_name][:casting] = true
    end
  end

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if self.healing_abilities.include?(ability_name) && !self.ticks.has_key?(event['ability']['guid'])
      if @cooldowns.has_key?(ability_name) && @cooldowns[ability_name][:active]
        ended_at = @cooldowns[ability_name][:cp].ended_at || @cooldowns[ability_name][:cp].started_at
        drop_cooldown(ability_name, ended_at, 'heal', true)
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
    if self.damage_reduction_cooldowns.keys.include? ability_name
      # set up an object to catch damage reduced by this ability
      if @cooldowns.has_key?(ability_name) && @cooldowns[ability_name][:active]
        ended_at = @cooldowns[ability_name][:cp].ended_at || @cooldowns[ability_name][:cp].started_at
        drop_cooldown(ability_name, ended_at, nil, true)
      end
      if @cooldowns[ability_name][:casting]
        @cooldowns[ability_name][:active] = true
        @cooldowns[ability_name][:casting] = false
      else
        gain_cooldown(ability_name, event['timestamp'], {damage_reduced: 0})
        @cooldowns[ability_name][:active] = true
      end
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::MANA
        ability_name ||= event['ability']['name']
        self.resources_hash[:heal_per_mana][ability_name] ||= {name: ability_name, mana_spent: 0, healing: 0, overhealing: 0}
        self.resources_hash[:heal_per_mana][ability_name][:mana_spent] += resource['cost'].to_i
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    # we want to track things like shields on ourselves too
    if (self.absorbing_abilities + self.external_damage_reduction_cooldowns.keys + self.damage_reduction_cooldowns.keys + self.external_healing_buff_abilities.keys + self.external_healing_abilities).include? ability_name
      apply_external_buff_event(event)
    end
  end

  def apply_external_buff_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if self.absorbing_abilities.include? ability_name
      apply_absorb(ability_name, target_id, event['absorb'].to_i, event['timestamp'])
    elsif (self.external_damage_reduction_cooldowns.keys + self.external_healing_buff_abilities.keys + self.external_healing_abilities).include? ability_name
      apply_external_cooldown(ability_name, target_id, @actors[target_id], event['timestamp'])
    end
    if self.damage_reduction_cooldowns.keys.include? ability_name
      if @cooldowns.has_key?(ability_name)
        @cooldowns[ability_name][:targets] ||= {}
        @cooldowns[ability_name][:targets][target_id] = true
      end
    end
  end

  def apply_external_buff_stack_event(event)
    # overwrite 
  end

  def drop_external_buff_event(event, refresh=false, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if self.absorbing_abilities.include? ability_name
      key = "#{ability_name}-#{@actors[target_id]}"
      if refresh # calculate how much shield was left for ourselves
        if @cooldowns.has_key?(key) && @cooldowns[key][:current_shield].to_i > 0
          leftover = @cooldowns[key][:current_shield].to_i - @cooldowns[key][:current_absorbing_done].to_i
        else
          leftover = 0
        end
      else
        leftover = event['absorb'].to_i
      end
      drop_absorb(ability_name, target_id, leftover, event['timestamp'])
    end
    if (self.external_damage_reduction_cooldowns.keys + self.external_healing_buff_abilities.keys + self.external_healing_abilities).include? ability_name
      drop_external_cooldown(ability_name, target_id, @actors[target_id], event['timestamp'])
    end
    if self.damage_reduction_cooldowns.keys.include? ability_name
      if @cooldowns.has_key?(ability_name)
        @cooldowns[ability_name][:targets] ||= {}
        @cooldowns[ability_name][:targets][target_id] = false
      end
    end
  end

  def drop_external_buff_stack_event(event)
    # overwrite
  end

  def absorb_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    extra_ability = event['extraAbility']['name'] rescue ''
    absorb(ability_name || event['ability']['name'], extra_ability, target_id, event['amount'].to_i, event['timestamp'])
  end

  def heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return unless @player_ids.include?(target_id)
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if self.healing_abilities.include?(ability_name) && @cooldowns[ability_name][:cp].nil?
      # probably started before the fight began
      gain_cooldown(ability_name, event['timestamp'], {healing_done: 0, overhealing_done: 0}, 'heal')
      @cooldowns[ability_name][:active] = true
    end
    if self.external_buff_abilities.include?(ability_name) && !@external_buffs[ability_name].has_key?(target_key)
      # probably started before the fight began
      apply_external_buff(ability_name, target_id, event['targetInstance'], event['timestamp'], {})
    end
    self.external_healing_buff_abilities.each do |buff_name, hash|
      buff_key = "#{buff_name}-#{@actors[target_id]}"
      if @cooldowns.has_key?(buff_key) && @cooldowns[buff_key][:active] && buff_name != ability_name
        increase_healing(@cooldowns[buff_key][:cp], ability_name || event['ability']['name'], event['amount'].to_i, event['overheal'].to_i, hash[:percent], event['timestamp'])
      end
    end
    heal(ability_name ||= event['ability']['name'], target_id, event['amount'].to_i, event['overheal'].to_i, event['tick'], event['timestamp'])
  end

  def handle_external_event(event) # mostly used for tracking healers' damage reduction
    ability_name = spell_name(event['ability']['guid']) rescue nil
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    if event['type'] == 'damage' && event['targetIsFriendly']
      self.damage_reduction_cooldowns.each do |name, hash|
        if @cooldowns.has_key?(name) && @cooldowns[name][:active] && @cooldowns[name].has_key?(:targets)
          if @cooldowns[name][:targets][target_id]
            reduce_damage(@cooldowns[name][:cp], ability_name || event['ability']['name'], event['amount'].to_i + event['absorbed'].to_i, hash[:percent], event['timestamp'])
          end
        end
      end
      self.external_damage_reduction_cooldowns.each do |name, hash|
        key = "#{name}-#{@actors[target_id]}"
        if @cooldowns.has_key?(key) && @cooldowns[key][:active]
          reduce_damage(@cooldowns[key][:cp], ability_name || event['ability']['name'], event['amount'].to_i + event['absorbed'].to_i, hash[:percent], event['timestamp'])
        end
      end
    elsif event['type'] == 'applybuff' && event['sourceID'].nil?
      # look for environment buffs caused by me
      if self.damage_reduction_cooldowns.keys.include? ability_name
        if @cooldowns.has_key?(ability_name)
          @cooldowns[ability_name][:targets] ||= {}
          @cooldowns[ability_name][:targets][target_id] = true
        end
      end
    elsif event['type'] == 'removebuff' && event['sourceID'].nil?
      # look for environment buffs caused by me
      if self.damage_reduction_cooldowns.keys.include? ability_name
        if @cooldowns.has_key?(ability_name)
          @cooldowns[ability_name][:targets] ||= {}
          @cooldowns[ability_name][:targets][target_id] = false
        end
      end
    end
  end

  def pet_heal_event(event)
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    self.kpi_hash[:pet_healing_done] = self.kpi_hash[:pet_healing_done].to_i + event['amount'] if event['targetIsFriendly']
    @kpi_parses[:healing_done].kpi_hash[:pet_healing_done] += event['amount'] if event['targetIsFriendly']
    kpi_key = "#{event['sourceID']}-#{ability_name}"
    @kpi_parses[:healing_done].details_hash[kpi_key] ||= {name: ability_name, heal: 0, overheal: 0}
    @kpi_parses[:healing_done].details_hash[kpi_key][:heal] += event['amount'].to_i
    @kpi_parses[:healing_done].details_hash[kpi_key][:overheal] += event['overheal'].to_i
    if !@pets.has_key?(event['sourceID'])
      # pet was probably summoned before the fight began
      pet_summon(event['sourceID'], self.started_at)
    end
    @pets[event['sourceID']][:pet].kpi_hash[:healing_done] = @pets[event['sourceID']][:pet].kpi_hash[:healing_done].to_i + event['amount'].to_i
    @pets[event['sourceID']][:pet].kpi_hash[:overhealing_done] = @pets[event['sourceID']][:pet].kpi_hash[:overhealing_done].to_i + event['overheal'].to_i
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]] ||= {name: @actors[target_id], healing: 0, overhealing: 0, hits: 0}
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:healing] += event['amount'].to_i
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:overhealing] += event['overheal'].to_i
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:hits] += 1
  end

  # setters

  def create_kpi_parses
    super
    @kpi_parses[:healing_done] = KpiParse.new(
      fight_parse_id: self.id, 
      name: :healing_done, 
      kpi_hash: {healing_done: 0, overhealing_done: 0, pet_healing_done: 0}, 
      details_hash: {}
    )
    @kpi_parses[:absorbing_done] = KpiParse.new(
      fight_parse_id: self.id, 
      name: :absorbing_done, 
      kpi_hash: {absorbing_done: 0, leftover_absorb: 0}, 
      details_hash: {}
    )
  end

  def apply_absorb(name, target_id, amount, timestamp)
    target_name = @actors[target_id]
    key = "#{name}-#{target_name}"
    @cooldowns[key] ||= {active: false, buffer: 0, cp: nil}
    if @cooldowns[key][:temp] && !@cooldowns[key][:cp].nil?
      ExternalCooldownParse.destroy(@cooldowns[key][:cp].id) 
      @cooldowns[key][:cp] = nil
    end
    if @cooldowns[key][:cp].nil?
      @cooldowns[key][:cp] = ExternalCooldownParse.new(fight_parse_id: self.id, target_id: target_id, target_name: target_name, cd_type: 'absorb', name: name, kpi_hash: {absorbing_done: 0, leftover_absorb: 0}, started_at: timestamp, ended_at: timestamp)
    end
    @cooldowns[key][:active] = true
    @cooldowns[key][:current_shield] = amount
    @cooldowns[key][:current_absorbing_done] = 0
    self.healing_buff_abilities.each do |buff_name, hash|
      if @cooldowns.has_key?(buff_name) && @cooldowns[buff_name][:active]
        unless self.healing_ignore_abilities.include? name
          if hash.has_key?(:percent)
            increased_amount = (amount - amount / (1 + hash[:percent])).to_i
          else
            increased_amount = amount
          end
          @cooldowns[buff_name][:cp].kpi_hash[:absorb_increase] = @cooldowns[buff_name][:cp].kpi_hash[:absorb_increase].to_i + increased_amount
          @cooldowns[buff_name][:cp].details_hash[name] ||= {name: name, total_absorb: 0, leftover: 0, count: 0}
          @cooldowns[buff_name][:cp].details_hash[name][:total_absorb] += increased_amount
          @cooldowns[buff_name][:cp].details_hash[name][:count] += 1
          # @cooldowns[buff_name][:cp].details_hash[name][:players][target_name] ||= {name: target_name, total: 0, leftover: 0}
          # @cooldowns[buff_name][:cp].details_hash[name][:players][target_name][:total] += increased_amount
          @cooldowns[key][:buffed] = buff_name
          @cooldowns[key][:increased_amount] = increased_amount
        end
      end
    end
  end

  def drop_absorb(name, target_id, amount, timestamp)
    target_name = @actors[target_id]
    key = "#{name}-#{target_name}"
    @cooldowns[key] ||= {active: false, buffer: 0, cp: nil}
    if @cooldowns[key][:cp].nil?
      @cooldowns[key][:cp] = ExternalCooldownParse.new(fight_parse_id: self.id, target_id: target_id, target_name: target_name, cd_type: 'absorb', name: name, kpi_hash: {absorbing_done: 0, leftover_absorb: 0}, started_at: self.started_at, ended_at: self.ended_at)
    end

    self.kpi_hash[:leftover_absorb] += amount
    @kpi_parses[:absorbing_done].kpi_hash[:leftover_absorb] += amount
    @kpi_parses[:absorbing_done].details_hash[name] ||= {name: name, absorb: 0, leftover_absorb: 0}
    @kpi_parses[:absorbing_done].details_hash[name][:leftover_absorb] += amount

    @cooldowns[key][:cp].kpi_hash[:leftover_absorb] += amount
    if !@cooldowns[key][:buffed].nil?
      leftover_amount = [amount, @cooldowns[key][:increased_amount].to_i].min 
      @cooldowns[@cooldowns[key][:buffed]][:cp].kpi_hash[:leftover_increase] = @cooldowns[@cooldowns[key][:buffed]][:cp].kpi_hash[:leftover_increase].to_i + leftover_amount
      @cooldowns[@cooldowns[key][:buffed]][:cp].details_hash[name] ||= {name: name, total_absorb: 0, leftover: 0, count: 0}
      @cooldowns[@cooldowns[key][:buffed]][:cp].details_hash[name][:leftover] += leftover_amount
      # @cooldowns[@cooldowns[key][:buffed]][:cp].details_hash[name][:players][target_name] ||= {name: target_name, total: 0, leftover: 0}
      # @cooldowns[@cooldowns[key][:buffed]][:cp].details_hash[name][:players][target_name][:leftover] += leftover_amount
      @cooldowns[@cooldowns[key][:buffed]][:cp].save
    end
    @cooldowns[key][:buffed] = nil
    @kpis[name] ||= []
    @kpis[name] << @cooldowns[key][:cp].kpi_hash
  end

  def absorb(name, attack_name, target_id, amount, timestamp)
    self.kpi_hash[:absorbing_done] += amount
    @kpi_parses[:absorbing_done].kpi_hash[:absorbing_done] += amount
    @kpi_parses[:absorbing_done].details_hash[name] ||= {name: name, absorb: 0, leftover_absorb: 0}
    @kpi_parses[:absorbing_done].details_hash[name][:absorb] += amount

    target_name = @actors[target_id]
    key = "#{name}-#{target_name}"
    if self.absorbing_abilities.include?(name)
      @cooldowns[key] ||= {active: false, buffer: 0, cp: nil}
      if @cooldowns[key][:cp].nil?
        # we need to setup a cooldown parse for this player
        @cooldowns[key][:cp] = ExternalCooldownParse.new(fight_parse_id: self.id, target_id: target_id, target_name: target_name, cd_type: 'absorb', name: name, kpi_hash: {absorbing_done: 0, leftover_absorb: 0}, started_at: self.started_at, ended_at: self.ended_at)
        @cooldowns[key][:active] = true
        @cooldowns[key][:current_absorbing_done] = 0
      end
      @cooldowns[key][:cp].kpi_hash[:absorbing_done] += amount
      @cooldowns[key][:cp].details_hash[attack_name] ||= {name: attack_name, amount: 0, hits: 0}
      @cooldowns[key][:cp].details_hash[attack_name][:amount] += amount
      @cooldowns[key][:cp].details_hash[attack_name][:hits] += 1
      @cooldowns[key][:current_absorbing_done] = @cooldowns[key][:current_absorbing_done].to_i + amount
    else # this is just a one-time absorb, rather than an absorb aura

    end
  end

  def heal(name, target_id, amount, overhealing, tick, timestamp)
    return unless @player_ids.include?(target_id)
    self.kpi_hash[:healing_done] += amount
    self.kpi_hash[:overhealing_done] += overhealing
    @kpi_parses[:healing_done].kpi_hash[:healing_done] += amount
    @kpi_parses[:healing_done].kpi_hash[:overhealing_done] += overhealing
    @kpi_parses[:healing_done].details_hash[name] ||= {name: name, heal: 0, overheal: 0}
    @kpi_parses[:healing_done].details_hash[name][:heal] += amount
    @kpi_parses[:healing_done].details_hash[name][:overheal] += overhealing
    if self.healing_abilities.include?(name) && !@cooldowns[name][:cp].nil?
      @cooldowns[name][:cp].kpi_hash[:healing_done] = @cooldowns[name][:cp].kpi_hash[:healing_done].to_i + amount
      @cooldowns[name][:cp].kpi_hash[:overhealing_done] = @cooldowns[name][:cp].kpi_hash[:overhealing_done].to_i + overhealing
      @cooldowns[name][:cp].kpi_hash[:hits] = @cooldowns[name][:cp].kpi_hash[:hits].to_i + 1
      @cooldowns[name][:cp].details_hash[target_id] ||= {name: @actors[target_id], healing: 0, overhealing: 0, hits: 0}
      @cooldowns[name][:cp].details_hash[target_id][:healing] += amount
      @cooldowns[name][:cp].details_hash[target_id][:overhealing] += overhealing
      @cooldowns[name][:cp].details_hash[target_id][:hits] += 1
      @cooldowns[name][:cp].ended_at = timestamp
    end
    if self.external_healing_abilities.include?(name)
      key = "#{name}-#{@actors[target_id]}"
      if @cooldowns.has_key?(key) && @cooldowns[key][:active]
        @cooldowns[key][:cp].kpi_hash[:healing_done] = @cooldowns[key][:cp].kpi_hash[:healing_done].to_i + amount
        @cooldowns[key][:cp].kpi_hash[:overhealing_done] = @cooldowns[key][:cp].kpi_hash[:overhealing_done].to_i + overhealing
        @cooldowns[key][:cp].kpi_hash[:hits] = @cooldowns[key][:cp].kpi_hash[:hits].to_i + 1
        @cooldowns[key][:cp].ended_at = timestamp
      end
    end
    self.healing_buff_abilities.each do |buff_name, hash|
      if @cooldowns.has_key?(buff_name) && @cooldowns[buff_name][:active]
        unless self.healing_ignore_abilities.include?(name) || (hash[:only_tick] && !tick)
          if hash.has_key?(:percent)
            increased_amount = (amount - amount / (1 + hash[:percent])).to_i
            increased_overhealing = (overhealing - overhealing / (1 + hash[:percent])).to_i
          else
            increased_amount = amount
            increased_overhealing = overhealing
          end
          @cooldowns[buff_name][:cp].kpi_hash[:healing_increase] = @cooldowns[buff_name][:cp].kpi_hash[:healing_increase].to_i + increased_amount
          @cooldowns[buff_name][:cp].kpi_hash[:overhealing_increase] = @cooldowns[buff_name][:cp].kpi_hash[:overhealing_increase].to_i + increased_overhealing
          @cooldowns[buff_name][:cp].details_hash[name] ||= {name: name, healing: 0, overhealing: 0, hits: 0}
          @cooldowns[buff_name][:cp].details_hash[name][:healing] += increased_amount
          @cooldowns[buff_name][:cp].details_hash[name][:overhealing] += increased_overhealing
          @cooldowns[buff_name][:cp].details_hash[name][:hits] += 1
        end
      end
    end
    self.resources_hash[:heal_per_mana][name] ||= {name: name, mana_spent: 0, healing: 0, overhealing: 0}
    self.resources_hash[:heal_per_mana][name][:healing] += amount
    self.resources_hash[:heal_per_mana][name][:overhealing] += overhealing
  end

  def increase_healing(cp, ability_name, amount, overheal, increase_percent, timestamp)
    increased_amount = (amount - amount / (1 + increase_percent)).to_i
    increased_overhealing = (overheal - overheal / (1 + increase_percent)).to_i
    cp.kpi_hash[:healing_increased] = cp.kpi_hash[:healing_increased].to_i + increased_amount
    cp.kpi_hash[:overhealing_increased] = cp.kpi_hash[:overhealing_increased].to_i + increased_overhealing
    cp.details_hash[ability_name] ||= {name: ability_name, healing_increased: 0, overhealing_increased: 0, hits: 0}
    cp.details_hash[ability_name][:healing_increased] += increased_amount
    cp.details_hash[ability_name][:overhealing_increased] += increased_overhealing
    cp.details_hash[ability_name][:hits] += 1
    cp.ended_at = timestamp
  end

  def reduce_damage(cp, ability_name, amount, reduction_percent, timestamp)
    reduced_amount = ((amount / (1 - reduction_percent)) - amount).to_i # 100% - actual
    cp.kpi_hash[:damage_reduced] = cp.kpi_hash[:damage_reduced].to_i + reduced_amount
    cp.details_hash[ability_name] ||= {name: ability_name, damage_reduced: 0, hits: 0}
    cp.details_hash[ability_name][:damage_reduced] += reduced_amount
    cp.details_hash[ability_name][:hits] += 1
    cp.ended_at = timestamp
  end

  def clean
    super
    @cooldowns.each do |name, hash|
      hash[:cp].save unless hash[:cp].nil?
    end
    self.resources_hash[:heal_per_mana].reject!{|key, hash| hash[:mana_spent].to_i == 0 || hash[:healing].to_i + hash[:overhealing].to_i == 0}
    self.resources_hash[:mana_spent] = self.resources_hash[:heal_per_mana].map{|spell, hash| hash[:mana_spent].to_i }.sum
    self.save
  end

end