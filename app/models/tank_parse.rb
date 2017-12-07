class TankParse < FightParse

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      damage_taken: 0,
      self_heal: 0,
      self_absorb: 0,
      external_heal: 0,
      external_absorb: 0
    }
    @absorbs = { # for saving shield sizes
      :self_absorb => 0,
      :external_absorb => 0
    }
    @hp_parses = { # for snapshotting health and shield sizes
      :hp => {},
      :self_heal => {},
      :external_heal => {},
      :self_absorb => {},
      :external_absorb => {},
      :mitigated => {}
    }
    @last_hp = 0
    @default_max_hp = 0
    @damage_by_source = {}
    # activating damage reduction by default leads to trouble
    self.damage_reduction_debuffs.keys.each do |reduc|
      @cooldowns[reduc][:active] = false unless !@cooldowns.has_key?(reduc)
    end
    self.damage_reduction_abilities.each do |reduc|
      @cooldowns[reduc[:name]][:active] = false unless !@cooldowns.has_key?(reduc[:name])
    end
    self.save
  end

  # settings

  def self.score_categories
    return {
      'casts_score' => 'Casts',
    }
  end

  def damage_reduction_abilities
    return []
  end

  def damage_reduction_debuffs
    return {}
  end

  def self.latest_version
    return super * 1000 + 1
  end

  # getters

  def dtps
    return self.kpi_hash[:damage_taken].to_i / self.fight_time
  end

  def shps
    return (self.kpi_hash[:self_heal].to_i + self.kpi_hash[:self_absorb].to_i) / self.fight_time
  end

  def ehps
    return (self.kpi_hash[:external_heal].to_i + self.kpi_hash[:external_absorb].to_i) / self.fight_time
  end

  def max_basic_bar
    return [self.dps, self.dtps, self.shps, self.ehps].max
  end

  # event handlers

  def handle_receive_event(event) # things done to you
    super
    # cast events have hp of the caster, rather than the target
    record_hp(event['hitPoints'], event['timestamp']) if event.has_key?('hitPoints') && event['type'] != 'cast'
  end

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if self.damage_reduction_debuffs.include? ability_name
      if @cooldowns[ability_name][:active]
        ended_at = @cooldowns[ability_name][:cp].ended_at || @cooldowns[ability_name][:cp].started_at
        drop_cooldown(ability_name, ended_at, 'cd', true)
      end
      # set up an object to catch damage reduction done by this ability
      gain_cooldown(ability_name, event['timestamp'], self.cooldown_abilities[ability_name][:kpi_hash])
    end
  end

  def gain_self_buff_event(event, refresh=false) # only tracks absorbs by default
    super
    if event.has_key?('absorb') # self absorb
      gain_absorb(event['ability']['guid'], event['sourceID'], event['absorb'], :self_absorb, event['hitPoints'], event['timestamp'])
    end
  end

  def lose_self_buff_event(event, force=true) # only tracks absorbs by default
    super
    if event.has_key?('absorb') # self absorb
      drop_absorb(event['ability']['guid'], event['sourceID'], event['absorb'], :self_absorb, event['hitPoints'], event['timestamp'])
    end
  end

  def gain_external_buff_event(event) # only tracks absorbs for now
    super
    if event['sourceID'] != event['targetID'] && event.has_key?('absorb') # external absorb
      gain_absorb(event['ability']['guid'], event['sourceID'], event['absorb'], :external_absorb, event['hitPoints'], event['timestamp'])
    end
  end

  def lose_external_buff_event(event, force=true) # only tracks absorbs for now
    super
    if event['sourceID'] != event['targetID'] && event.has_key?('absorb') # external absorb
      drop_absorb(event['ability']['guid'], event['sourceID'], event['absorb'], :external_absorb, event['hitPoints'], event['timestamp'])
    end
  end

  def absorb_event(event)
    super
    if event['targetID'] == event['sourceID']
      ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
      absorb(:self_absorb, ability_name, event['ability']['guid'], event['sourceID'], event['amount'], event['hitPoints'], event['timestamp'])
    end
  end

  def heal_event(event)
    super
    if event['targetID'] == event['sourceID']
      ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
      heal(:self_heal, ability_name, event['sourceID'], event['amount'].to_i, event['overheal'].to_i, event['hitPoints'], event['timestamp'])
    end
  end

  def receive_absorb_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    absorb(:external_absorb, ability_name, event['ability']['guid'], event['sourceID'], event['amount'], event['hitPoints'], event['timestamp'])
  end

  def receive_heal_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    heal(:external_heal, ability_name, event['sourceID'], event['amount'].to_i, event['overheal'].to_i, event['hitPoints'], event['timestamp'])
  end

  def receive_damage_event(event)
    super
    # check if cooldowns need to drop
    @cooldowns.each do |key, hash|
      drop_cooldown(key, event['timestamp']) if hash[:buffer] != 0
    end
    self.kpi_hash[:damage_taken] += event['amount']
    @kpi_parses[:damage_taken].kpi_hash[:damage_taken] += event['amount']
    source = @actors[event['sourceID']]
    @kpi_parses[:damage_taken].details_hash[source] ||= {amount: 0}
    @kpi_parses[:damage_taken].details_hash[source][:amount] += event['amount']

    return if event['sourceIsFriendly']
    return if (event['amount'] + event['absorbed']) == 0

    event['sourceID'] ||= -1
    @default_max_hp = event['maxHitPoints'] if event.has_key?('maxHitPoints') && @default_max_hp == 0

    # work our way back up the mitigation stack to see how much each ability mitigated
    amount = after_mitigation = event['amount'] + event['absorbed']
    key = "#{event['sourceID']}-#{event['ability']['guid']}"
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']

    self.damage_reduction_debuffs.each do |debuff_name, debuff|
      target_key = "#{event['sourceID'].to_i}-#{event['sourceInstance'].to_i}"
      if @debuffs.has_key?(debuff_name) && @debuffs[debuff_name].has_key?(target_key) && @debuffs[debuff_name][target_key][:active]
        reduced_amount = ((amount / (1 - debuff[:amount])) - amount).to_i # 100% - actual
        if !@cooldowns[debuff_name][:cp].details_hash.has_key?(key)
          @cooldowns[debuff_name][:cp].details_hash[key] = {source: source, name: ability_name, casts: 0, amount: 0}
        end
        @cooldowns[debuff_name][:cp].kpi_hash[:reduced_amount] += reduced_amount
        @cooldowns[debuff_name][:cp].details_hash[key][:amount] += reduced_amount
        @cooldowns[debuff_name][:cp].details_hash[key][:casts] += 1 unless debuff[:no_count]
        @cooldowns[debuff_name][:cp].ended_at = event['timestamp']
        amount += reduced_amount
      end
    end
    self.damage_reduction_abilities.each do |reduc|
      if @cooldowns.has_key?(reduc[:name]) && @cooldowns[reduc[:name]][:active]
        unless reduc.has_key?(:type) && event['ability']['type'] != reduc[:type]
          unless reduc.has_key?(:exclude_type) && event['ability']['type'] == reduc[:exclude_type]
            unless reduc[:tick] && !event['tick']
              reduced_amount = ((amount / (1 - reduc[:amount])) - amount).to_i # 100% - actual
              @cooldowns[reduc[:name]][:cp].kpi_hash[:reduced_amount] += reduced_amount
              if !@cooldowns[reduc[:name]][:cp].details_hash.has_key?(key)
               @cooldowns[reduc[:name]][:cp].details_hash[key] = {source: source, name: ability_name, casts: 0, amount: 0}
               @cooldowns[reduc[:name]][:cp].details_hash[key].merge! reduc[:details_hash] if reduc.has_key?(:details_hash)
              end
              @cooldowns[reduc[:name]][:cp].details_hash[key][:amount] += reduced_amount
              @cooldowns[reduc[:name]][:cp].details_hash[key][:casts] += 1 unless reduc[:no_count]
              amount += reduced_amount
            end
          end
        end
      end
    end
    # record the attack's initial damage
    @damage_by_source[key] ||= {count: 0, total: 0}
    @damage_by_source[key][:total] += amount
    @damage_by_source[key][:count] += 1

    # record how much of the damage was mitigated
    mitigated_damage = amount - after_mitigation
    self.mitigate(mitigated_damage, event['hitPoints'], event['timestamp']) if mitigated_damage > 0

    return amount
  end

  # setters

  def create_kpi_parses
    super
    @kpi_parses[:damage_taken] = KpiParse.new(
      fight_parse_id: self.id, 
      name: :damage_taken, 
      kpi_hash: {damage_taken: 0}, 
      details_hash: {}
    )
    @kpi_parses[:self_healing] = KpiParse.new(
      fight_parse_id: self.id, 
      name: :self_healing, 
      kpi_hash: {self_heal: 0, self_absorb: 0}, 
      details_hash: {}
    )
    @kpi_parses[:external_healing] = KpiParse.new(
      fight_parse_id: self.id, 
      name: :external_healing, 
      kpi_hash: {external_heal: 0, external_absorb: 0}, 
      details_hash: {}
    )
  end

  def gain_absorb(guid, source_id, amount, type, hitPoints, timestamp) # type is :self_absorb or :external_absorb
    @absorbs[type] += amount - @absorbs["#{source_id}.#{guid}"].to_i # if the shield was refreshed, just add the difference
    @absorbs["#{source_id}.#{guid}"] = amount # refresh the shield size
    time = (timestamp - self.started_at)
    @hp_parses[type][time] = @absorbs[type] # save the total shield size
    record_hp(hitPoints, timestamp)
  end

  def drop_absorb(guid, source_id, amount, type, hitPoints, timestamp) # type is :self_absorb or :external_absorb
    if @absorbs.has_key?("#{source_id}.#{guid}") # if this isn't here, we never recorded the application of the shield
      @absorbs[type] -= amount
      @absorbs["#{source_id}.#{guid}"] = 0
    end
    time = (timestamp - self.started_at)
    @hp_parses[type][time] = @absorbs[type]
    record_hp(hitPoints, timestamp)
  end

  def absorb(key, name, guid, source_id, amount, hitPoints, timestamp)
    # key = :self_absorb or :external_absorb
    self.kpi_hash[key] += amount if self.kpi_hash.has_key?(key)
    if key == :self_absorb
      @kpi_parses[:self_healing].kpi_hash[:self_absorb] += amount
      @kpi_parses[:self_healing].details_hash[name] ||= {absorb: 0, heal: 0}
      @kpi_parses[:self_healing].details_hash[name][:absorb] += amount
    elsif key == :external_absorb
      @kpi_parses[:external_healing].kpi_hash[:external_absorb] += amount
      @kpi_parses[:external_healing].details_hash[@actors[source_id]] ||= {absorb: 0, heal: 0}
      @kpi_parses[:external_healing].details_hash[@actors[source_id]][:absorb] += amount
    end
    time = (timestamp - self.started_at)
    if @absorbs.has_key?("#{source_id}.#{guid}") # if this isn't here, we never recorded the application of the shield
      @absorbs["#{source_id}.#{guid}"] -= amount 
      @absorbs[key] -= amount # reduce total shield size
      @hp_parses[key][time] = @absorbs[key]
    else # this is just a one-time absorb, rather than an absorb aura
      @hp_parses[:mitigated][time] = @hp_parses[:mitigated][time].to_i + amount
    end
    record_hp(hitPoints, timestamp)
  end

  def heal(key, name, source, amount, overhealing, hitPoints, timestamp)
    # key = :self_heal or :external_heal
    self.kpi_hash[key] += amount if self.kpi_hash.has_key?(key)
    if key == :self_heal
      @kpi_parses[:self_healing].kpi_hash[:self_heal] += amount
      @kpi_parses[:self_healing].details_hash[name] ||= {absorb: 0, heal: 0}
      @kpi_parses[:self_healing].details_hash[name][:heal] += amount
    elsif key == :external_heal
      @kpi_parses[:external_healing].kpi_hash[:external_heal] += amount
      @kpi_parses[:external_healing].details_hash[@actors[source]] ||= {absorb: 0, heal: 0}
      @kpi_parses[:external_healing].details_hash[@actors[source]][:heal] += amount
    end
    time = (timestamp - self.started_at)
    @hp_parses[key][time] ||= 0
    @hp_parses[key][time] += amount
    record_hp(hitPoints, timestamp)
  end

  def mitigate(amount, hitPoints, timestamp)
    time = (timestamp - self.started_at)
    @hp_parses[:mitigated][time] ||= 0
    @hp_parses[:mitigated][time] += amount
    record_hp(hitPoints, timestamp)
  end

  def record_hp(hitPoints, timestamp)
    hitPoints ||= @last_hp
    @last_hp = hitPoints
    time = (timestamp - self.started_at)
    @hp_parses[:hp][time] = hitPoints
  end

  def save_hp
    @hp_parses.each do |key, hash|
      next if key == :hp
      prev = [0, 0]
      @hp_parses[:hp].each do |time, value|
        if hash.has_key?(time)
          prev = [time, hash[time]]
        else
          if key == :self_heal || key == :external_heal || key == :mitigated
            if time - prev[0] < 1000 # make the spikes easier to see in the graph
              hash[time] = prev[1]
            else
              hash[time] = 0
            end
          else
            hash[time] = prev[1]
          end
        end
      end
    end

    @hp_parses.each {|key, value| @hp_parses[key] = value.sort_by{|time, value| time} }
    S3_BUCKET.object("hp/#{self.report_id}_#{self.fight_id}_#{self.player_id}.json").put(body: @hp_parses.to_json)
  end

  def clean
    super
    save_hp
  end

end