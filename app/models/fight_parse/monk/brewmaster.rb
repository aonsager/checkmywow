class FightParse::Monk::Brewmaster < TankParse
  include Filterable
  self.table_name = :fp_monk_brew

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 5
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

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
    }
    self.resources_hash = {
      capped_time: 0,
      isb_stagger: 0,
      damage_to_stagger: 0,
      damage_from_stagger: 0,
      stagger_purified: 0,
      brewstache_uptime: 0,
      boc_gained: 0,
      boc_used: 0,
      boc_abilities: {},
    }
    self.cooldowns_hash = {
      dh_reduced: 0,
      zm_reduced: 0,
      fb_reduced: 0,
      keg_avoided: 0,
    }
    @stagger_parses = { # for snapshotting health and shield sizes
      :stagger => {},
      :ironskin => {},
      :purify => {},
    }
    self.casts_hash['Tiger Palm'] = []
    self.casts_hash['Ironskin Brew'] = []
    self.casts_hash['Purifying Brew'] = []
    self.save
    @stagger_pool = 0
    @ironskin_pool = 0

    @cooldowns['Dampen Harm'][:attacks] = []
  end

  # settings

  def spell_name(id)
    return {
      121253 => 'Keg Smash',
      100780 => 'Tiger Palm',
      116847 => 'Rushing Jade Wind',
      115181 => 'Breath of Fire',
      205523 => 'Blackout Strike',
      123986 => 'Chi Burst',
      115098 => 'Chi Wave',
      124255 => 'Stagger',
      115069 => 'Stagger',
      115308 => 'Ironskin Brew',
      215479 => 'Ironskin Brew',
      119582 => 'Purifying Brew',
      122783 => 'Diffuse Magic',
      122278 => 'Dampen Harm',
      115203 => 'Fortifying Brew',
      120954 => 'Fortifying Brew',
      115176 => 'Zen Meditation',
      196721 => 'Light Brewing',
      115399 => 'Black Ox Brew',
      196738 => 'Elusive Dance',
      228563 => 'Blackout Combo',
      196736 => 'Blackout Combo',
      214326 => 'Exploding Keg',
      214373 => 'Brew-Stache',
      238129 => 'Quick Sip',
      213055 => 'Staggering Around',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Black Ox Brew'] = {cd: 90} if talent(2) == 'Black Ox Brew'
    local['Exploding Keg'] = {cd: 75}
    local['Ironskin/Purifying Brew'] = {cd: (self.brew_cooldown * self.haste_reduction_ratio), extra: self.brew_charges, reduction: self.brew_reduction}
    local['Keg Smash'] = {cd: (8 * self.haste_reduction_ratio)}
    local['Breath of Fire'] = {cd: 15}
    local['Chi Burst'] = {cd: 30} if talent(0) == 'Chi Burst'
    local['Chi Wave'] = {cd: 15} if talent(0) == 'Chi Wave'
    local['Blackout Strike'] = {cd: 3}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Zen Meditation'] = {cd: 180}
    bars['cd']['Fortifying Brew'] = {cd: 180}
    bars['cd']['Dampen Harm'] = {cd: 90, optional: true}
    bars['cd']['Ironskin Brew'] = {}

    return bars
  end

  def cooldown_abilities
    return {
      'Ironskin Brew' => {kpi_hash: {absorbed_amount: 0}},
      'Purifying Brew' => {kpi_hash: {purified_amount: 0}},
      'Dampen Harm' => {kpi_hash: {reduced_amount: 0}},
      'Fortifying Brew' => {kpi_hash: {reduced_amount: 0}},
      'Zen Meditation' => {kpi_hash: {reduced_amount: 0}},
      'Exploding Keg' => {kpi_hash: {reduced_amount: 0}},
    }
  end

  def damage_reduction_abilities
    return [
      {name: 'Fortifying Brew', amount: 0.2},
      {name: 'Zen Meditation', amount: 0.6},
    ]
  end

  def uptime_abilities
    local = {
      'Blackout Combo' => {},
    }
    return super.merge local
  end

  def buff_abilities
    return {
      'Brew-Stache' => {},
    }
  end

  def debuff_abilities
    return {
      'Exploding Keg' => {},
    }
  end

  def show_resources
    return [ResourceType::ENERGY]
  end

  def graph_series
    return {
      'stagger' => {
          name: 'Stagger',
          yaxis: 'Amount',
          series: [
            {
              name: 'Ironskin Brew',
              key: 'ironskin',
              color: '#29C2FF',
              stack: 0,
              type: 'areaspline',
              connectNulls: false,
            },
            {
              name: 'Stagger',
              key: 'stagger',
              color: '#1fb47a',
              stack: 0,
              type: 'areaspline',
              connectNulls: false,
            },
            {
              name: 'Purifying Brew',
              key: 'purify',
              color: '#CC9DFD',
              stack: 1,
              type: 'areaspline',
              connectNulls: false,
            },
          ]
        }
    }
  end

  # getters

  def max_cooldown
    return [self.cooldowns_hash[:dh_reduced], self.cooldowns_hash[:dm_reduced], self.cooldowns_hash[:zm_reduced], self.cooldowns_hash[:fb_reduced]].max
  end

  def purify_percent
    percent = talent(6) == 'Elusive Dance' ? 0.6 : 0.4
    percent += artifact('Staggering Around').to_i * 0.1
    return percent
  end

  def ironskin_percent
    return 0.4
  end

  def brew_charges
    begin
      if talent(2) == 'Light Brewing'
        return 4
      else
        return 3
      end
    rescue 
      return 3
    end
  end

  def brew_cooldown
    begin
      if talent(2) == 'Light Brewing'
        return 18
      else
        return 21
      end
    rescue
      return 21
    end
  end

  def brew_reduction
    return (self.casts_hash['Keg Smash'].count rescue 0) * 4 + (self.casts_hash['Tiger Palm'].count rescue 0) * 1
  end

  def blackout_abilities
    return [
      'Tiger Palm',
      'Breath of Fire',
      'Keg Smash',
      'Ironskin Brew',
      'Purifying Brew',
    ]
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Ironskin Brew'
      self.casts_hash['Ironskin/Purifying Brew'] << event['timestamp']
      self.casts_hash['Ironskin Brew'] << event['timestamp']
      if @cooldowns['Ironskin Brew'][:temp]
        # fix for starting with ISB active, since extending doesn't count as a refresh
        gain_cooldown('Ironskin Brew', event['timestamp'], self.cooldown_abilities['Ironskin Brew'][:kpi_hash])
      end
      purify(event['timestamp'], 0.05) if artifact('Quick Sip')
    elsif ability_name == 'Purifying Brew'
      self.casts_hash['Ironskin/Purifying Brew'] << event['timestamp']
      self.casts_hash['Purifying Brew'] << event['timestamp']
      purified_amount = purify(event['timestamp'])
      gain_cooldown('Purifying Brew', event['timestamp'], {purified_amount: purified_amount})
      drop_cooldown('Purifying Brew', event['timestamp'], nil, true)
    elsif ability_name == 'Tiger Palm'
      self.casts_hash['Tiger Palm'] << event['timestamp']
    elsif ability_name == 'Blackout Strike'
      self.resources_hash[:boc_gained] += 1
    elsif ability_name == 'Exploding Keg'
      gain_cooldown('Exploding Keg', event['timestamp'], {reduced_amount: 0})
    end
    if @uptimes['Blackout Combo'][:active] && self.blackout_abilities.include?(ability_name)
      self.resources_hash[:boc_used] += 1
      self.resources_hash[:boc_abilities][ability_name] ||= {name: ability_name, casts: 0}
      self.resources_hash[:boc_abilities][ability_name][:casts] += 1
    end
    (event['classResources'] || []).each do |resource|
      check_resource_cap(resource['amount'], resource['max'], event['timestamp']) if resource['type'] == ResourceType::ENERGY
    end
  end

  def purify(timestamp, percent = self.purify_percent)
    purified_amount = ((@stagger_pool + @ironskin_pool) * percent).to_i
    ironskin_amount = (purified_amount * @ironskin_pool / (@ironskin_pool + @stagger_pool)).to_i rescue 0
    @ironskin_pool -= ironskin_amount
    @stagger_pool -= (purified_amount - ironskin_amount)
    self.resources_hash[:stagger_purified] += purified_amount
    record_stagger(:ironskin, @ironskin_pool, timestamp)
    record_stagger(:stagger, @stagger_pool, timestamp)
    record_stagger(:purify, purified_amount, timestamp)
    return purified_amount
  end

  def gain_self_buff_event(event, refresh=false)
    super
    # in addition to normal cd tracking
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Dampen Harm'
      @cooldowns['Dampen Harm'][:attacks] = []   
    end
  end

  def lose_self_buff_event(event, force=true)
    super
    # in addition to normal cd tracking
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Ironskin Brew'
      @stagger_pool += @ironskin_pool
      @ironskin_pool = 0
      record_stagger(:ironskin, @ironskin_pool, event['timestamp'])
      record_stagger(:stagger, @stagger_pool, event['timestamp'])
    end
  end

  def remove_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Exploding Keg' && @cooldowns['Exploding Keg'][:active]
      drop_cooldown('Exploding Keg', @cooldowns['Exploding Keg'][:cp].ended_at, nil, true)
    end
  end

  def absorb_event(event)
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Stagger'
      stagger(event['timestamp'], event['amount'], event['attackerID'], event['extraAbility']['guid'], event['extraAbility']['name'], event['hitPoints'])
      return
    end
    super
  end

  def receive_damage_event(event)
    ability_name = spell_name(event['ability']['guid'])
    source_key = "#{event['sourceID']}-#{event['sourceInstance'].to_i}"

    if ability_name == 'Stagger'
      amount = event['amount'].to_i + event['absorbed'].to_i
      self.resources_hash[:damage_from_stagger] += amount
      ironskin_amount = (amount * @ironskin_pool / (@ironskin_pool + @stagger_pool)).to_i rescue 0
      @ironskin_pool -= ironskin_amount
      @stagger_pool -= (amount - ironskin_amount)
      record_stagger(:stagger, @ironskin_pool, event['timestamp'])
      record_stagger(:stagger, @stagger_pool, event['timestamp'])
    end

    amount = super

    if event['hitType'] == 0 && ability_name == 'Melee' && @debuffs.has_key?('Exploding Keg') && @debuffs['Exploding Keg'].has_key?(source_key) && @debuffs['Exploding Keg'][source_key][:active]
      miss_with_keg(event['sourceID'], event['ability']['guid'], event['ability']['name'], event['timestamp'])
    end

    key = "#{event['sourceID']}-#{event['ability']['guid']}"
    if @cooldowns['Dampen Harm'][:active] && !event['tick'] # ignore ticks for DH
      if @cooldowns['Dampen Harm'][:attacks].size > 0 && (@cooldowns['Dampen Harm'][:attacks].last[:timestamp] - event['timestamp']).abs <= 50 && @cooldowns['Dampen Harm'][:attacks].last[:ability_id] == event['ability']['guid'] && @cooldowns['Dampen Harm'][:attacks].last[:staggered] > 0
        @cooldowns['Dampen Harm'][:attacks].last[:source] = @actors[event['sourceID']]
        @cooldowns['Dampen Harm'][:attacks].last[:name] = event['ability']['name']
        @cooldowns['Dampen Harm'][:attacks].last[:amount] = amount
        @cooldowns['Dampen Harm'][:attacks].last[:max_hp] = event['maxHitPoints']
      else
        @cooldowns['Dampen Harm'][:attacks] << {timestamp: event['timestamp'], source: @actors[event['sourceID']], ability_id: event['ability']['guid'], name: event['ability']['name'], amount: amount, staggered: 0, hp: event['hitPoints'], max_hp: event['maxHitPoints']}
      end
    end
  end

  # setters

  def drop_cooldown(name, timestamp, subname = nil, force = false, key = nil)
    if super # if the cooldown was actually dropped
      calculate_dh if name == 'Dampen Harm' # figure out which attacks may have triggered DH
    end
  end

  def miss_with_keg(source_id, ability_id, ability_name, timestamp)
    source ||= -1
    key = "#{source_id}-#{ability_id}"
    @cooldowns['Exploding Keg'][:cp].details_hash[key] ||= {source: @actors[source_id], name: ability_name, dodged: 0, avg: 0}
    @cooldowns['Exploding Keg'][:cp].details_hash[key][:dodged] += 1
    @cooldowns['Exploding Keg'][:cp].ended_at = timestamp
  end

  def calculate_dh
    @cooldowns['Dampen Harm'][:cp].details_hash = {}
    @cooldowns['Dampen Harm'][:attacks].reject! {|attack| attack[:ability_id] == 0}
    # fill missing max_hp values, because it's not recorded if the attack is fully absorbed(?)
    @cooldowns['Dampen Harm'][:attacks].each {|attack| attack[:max_hp] = @default_max_hp if attack[:max_hp].nil? }
    # sort by damage % of max hp
    @cooldowns['Dampen Harm'][:attacks].sort! {|a, b| (b[:amount].to_i - b[:staggered].to_i).to_f / b[:max_hp].to_i <=> (a[:amount].to_i - a[:staggered].to_i).to_f / a[:max_hp].to_i}
    # grab the highest 3 attacks and see if they may have triggered DH
    0.upto(2).each do |i|
      a = @cooldowns['Dampen Harm'][:attacks][i]
      break if a.nil?
      percent = (a[:amount].to_i - a[:staggered].to_i).to_f / a[:max_hp]
      if percent >= 0.105 # might have reduced
        @cooldowns['Dampen Harm'][:cp].details_hash[i] = {source: a[:source], ability_id: a[:ability_id], name: a[:name], amount: a[:amount].to_i - a[:staggered].to_i, staggered: a[:staggered].to_i, percent: percent, sure: 'maybe', max_hp: a[:max_hp]}
        if percent >= 0.15 || @cooldowns['Dampen Harm'][:buffer] - @cooldowns['Dampen Harm'][:cp].started_at < 45000 # definitely was reduced
          @cooldowns['Dampen Harm'][:cp].details_hash[i][:sure] = 'yes'
        end 
        @cooldowns['Dampen Harm'][:cp].kpi_hash[:reduced_amount] += (a[:amount].to_i - a[:staggered].to_i)
        # save this to the mitigation hp graph
        self.mitigate(a[:amount].to_i - a[:staggered].to_i, a[:hp], a[:timestamp])
      end
    end
    @cooldowns['Dampen Harm'][:cp].save
  end

  def stagger(timestamp, amount, source_id, ability_id, ability_name, hitPoints)
    key = "#{source_id}-#{ability_id}"
    source = @actors[source_id]
    @stagger_pool += amount

    self.resources_hash[:damage_to_stagger] += amount
    if @cooldowns['Dampen Harm'][:active] # negate stagger from our recorded damage of this attack
      if !@cooldowns['Dampen Harm'][:attacks].last.nil? && (@cooldowns['Dampen Harm'][:attacks].last[:timestamp] - timestamp).abs <= 50 && @cooldowns['Dampen Harm'][:attacks].last[:ability_id] == ability_id && @cooldowns['Dampen Harm'][:attacks].last[:staggered] == 0
        @cooldowns['Dampen Harm'][:attacks].last[:staggered] = amount
      else
        @cooldowns['Dampen Harm'][:attacks] << {timestamp: timestamp, ability_id: ability_id, name: '', amount: 0, staggered: amount, max_hp: nil}
      end
    end
    if @cooldowns['Ironskin Brew'][:active] && !@cooldowns['Ironskin Brew'][:temp]
      @cooldowns['Ironskin Brew'][:cp].kpi_hash[:absorbed_amount] += amount
      self.resources_hash[:isb_stagger] += amount
      ironskin_amount = (amount * self.ironskin_percent).to_i

      @cooldowns['Ironskin Brew'][:cp].details_hash[key] ||= {source: source, name: ability_name, casts: 0, amount: 0}
      @cooldowns['Ironskin Brew'][:cp].details_hash[key][:amount] += ironskin_amount
      @cooldowns['Ironskin Brew'][:cp].details_hash[key][:casts] += 1
      @ironskin_pool += ironskin_amount
      @stagger_pool -= ironskin_amount
    end
    record_stagger(:ironskin, @ironskin_pool, timestamp)
    record_stagger(:stagger, @stagger_pool, timestamp)
    self.mitigate(amount, hitPoints, timestamp)
  end

  def record_stagger(key, amount, timestamp)
    time = (timestamp - self.started_at)
    @stagger_parses[key][time] = amount
  end

  def save_stagger
    @stagger_parses.each do |key, hash|
      next if key == :stagger
      prev = [0, 0]
      @stagger_parses[:stagger].each do |time, value|
        if hash.has_key?(time)
          prev = [time, hash[time]]
        else
          if key == :purify
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

    @stagger_parses.each {|key, value| @stagger_parses[key] = value.sort_by{|time, value| time} }
    S3_BUCKET.object("brewmaster/stagger_#{self.report_id}_#{self.fight_id}_#{self.player_id}.json").put(body: @stagger_parses.to_json)
  end

  def clean
    super
    save_stagger
    # calculate total damage avoided with Exploding Keg
    self.cooldown_parses.where(name: 'Exploding Keg').each do |keg|
      keg.kpi_hash[:reduced_amount] = 0
      keg.details_hash.each do |key, ability|
        if @damage_by_source.has_key?(key)
          ability[:avg] = @damage_by_source[key][:total] / @damage_by_source[key][:count]
        else
          ability[:avg] = 0 #TODO get data from other parses?
        end
        avoided_dmg = ability[:dodged] * ability[:avg]
        keg.kpi_hash[:reduced_amount] += avoided_dmg
      end
      self.cooldowns_hash[:keg_avoided] += keg.kpi_hash[:reduced_amount]
      keg.save
    end
    self.resources_hash[:brewstache_uptime] = @kpis['Brew-Stache'].first[:uptime].to_i rescue 0
    self.cooldowns_hash[:dh_reduced] = @kpis['Dampen Harm'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:zm_reduced] = @kpis['Zen Meditation'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
    self.cooldowns_hash[:fb_reduced] = @kpis['Fortifying Brew'].map{|kpi| kpi[:reduced_amount]}.sum rescue 0
  end

end