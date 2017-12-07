class FightParse::Hunter::Marksmanship < FightParse
  include Filterable
  self.table_name = :fp_hunter_marks
  
  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      vulnerable_damage: 0,
      vulnerable_ablities: {},
      vulnerable_count: 0,
      patient_sniper_casts: {1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0, 7=>0, 'No Cast'=>0},
      lnl_procs: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      marking_procs: 0,
      marking_wasted: 0,
      marking_cd: 0,
      hunters_mark: 0,
      marking_abilities: {},
      vulnerable_uptime: 0,
      vulnerable_downtime: 0,
      focus_gain: 0,
      focus_waste: 0,
      focus_abilities: {},
      focus_spent: {},
    }
    self.cooldowns_hash = {
      trueshot_damage: 0,
      bullseye_damage: 0,
      bullseye_uptime: 0,
    }
    @resources = {
      "r#{ResourceType::FOCUS}" => 0,
      "r#{ResourceType::FOCUS}_max" => self.max_focus,
    }
    @focus = 0
    @vuln_hits = []
    @last_cast
    self.save
  end

  # settings

  def uptime_abilities
    local = {
      'Marking Targets' => {},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Bullseye' => {},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Trueshot' => {kpi_hash: {damage_done: 0}},
      'Bullseye x30' => {},
    }
    return super.merge local
  end

  def dps_abilities
    local = {

    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Trueshot' => {},
      'Bullseye x30' => {},
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Hunter\'s Mark' => {},
      'Vulnerable' => {},
    }
    return super.merge local
  end

  def track_casts
    local = {}
    local['Trueshot'] = {cd: 180}
    local['Windburst'] = {cd: 20}
    local['Barrage'] = {cd: 20} if talent(5) == 'Barrage'
    local['Marked Shot'] = {cd: 15, max: self.resources_hash[:hunters_mark]}
    local['Black Arrow'] = {cd: (15 * self.haste_reduction_ratio)} if talent(1) == 'Black Arrow'
    local['Sidewinders'] = {cd: (12 * self.haste_reduction_ratio), extra: 1} if talent(6) == 'Sidewinders'
    local['Aimed Shot'] = {cd: 1.0 * self.fight_time / self.max_aimed_shot, extra: self.kpi_hash[:lnl_procs].to_i * 2}
    local['Aimed Shot'][:cd] = nil if self.max_aimed_shot == 0 # fix
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Trueshot'] = {cd: 180}
    bars['cd']['Bullseye x30'] = {cd: nil}
    return bars
  end

  def track_resources
    return [ResourceType::FOCUS]
  end

  def self.latest_version
    return super * 1000 + 5
  end

  def self.latest_hotfix
    return super * 1000 + 3
  end

  # getters

  def spell_name(id)
    return {
      223138 => 'Marking Targets',
      185358 => 'Arcane Shot',
      2643 => 'Multi-Shot',
      214579 => 'Sidewinders',
      185901 => 'Marked Shot',
      19434 => 'Aimed Shot',
      191043 => 'Aimed Shot (Wind Arrow)',
      187131 => 'Vulnerable',
      234588 => 'Patient Sniper',
      120360 => 'Barrage',
      120361 => 'Barrage',
      193526 => 'Trueshot',
      194599 => 'Black Arrow',
      204147 => 'Windburst',
      194594 => 'Lock and Load',
      204090 => 'Bullseye',
    }[id] || super(id)
  end

  def max_focus
    return 130
  end

  def vuln_duration
    return 7000
  end

  def max_aimed_shot
    other_focus = (self.resources_hash[:focus_spent] || {}).map{|spell, num| spell == 'Aimed Shot' ? 0 : num.to_i}.sum rescue 0
    return (self.resources_hash[:focus_gain].to_i + self.resources_hash[:focus_waste].to_i - other_focus) / 50
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Aimed Shot' && @debuffs['Vulnerable'].has_key?(target_key) && @debuffs['Vulnerable'][target_key][:active]
      ends_at = @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_applied].to_i + self.vuln_duration
      time_left = 1 + (ends_at - event['timestamp']) / 1000
      # record to be saved when the debuff drops
      @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_aimed] = time_left
      # mark that aimed shot hit a vuln started at this time, so we can ignore secondary vulns
      began_cast = @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:began_cast].to_i
      @vuln_hits << began_cast unless @vuln_hits.include?(began_cast)
    end
    @last_cast = event['timestamp']

    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::FOCUS
        @focus = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
        if resource['cost'].to_i > 0
          self.resources_hash[:focus_spent][ability_name] ||= 0
          self.resources_hash[:focus_spent][ability_name] += resource['cost'].to_i
        end
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    self.kpi_hash[:lnl_procs] += 1 if ability_name == 'Lock and Load'
  end

  def gain_self_buff_stack_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Bullseye' && event['stack'] == 30
      gain_cooldown('Bullseye x30', event['timestamp'], {damage_done: 0})
    end
  end

  def lose_self_buff_event(event, force=true)
    ability_name = spell_name(event['ability']['guid'])
    # check before temp is overwritten
    if ability_name == 'Trueshot' && @cooldowns['Trueshot'][:temp]
      # ignore all previous aimed shots
      self.kpi_hash[:vulnerable_count] = 0
      self.kpi_hash[:patient_sniper_casts] = {1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0, 7=>0, 'No Cast'=>0}
      @debuffs['Vulnerable'].each do |target_key, hash|
        hash[:dp].kpi_hash[:trueshot] = true
      end
    end

    super

    if ability_name == 'Bullseye' && is_active?('Bullseye x30', event['timestamp'])
      drop_cooldown('Bullseye x30', event['timestamp'])
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if @debuffs['Vulnerable'].has_key?(target_key) && @debuffs['Vulnerable'][target_key][:active] && !event['tick']
      self.kpi_hash[:vulnerable_damage] += event['amount'].to_i
      self.kpi_hash[:vulnerable_ablities][ability_name] ||= {name: ability_name, casts: 0, damage: 0}
      self.kpi_hash[:vulnerable_ablities][ability_name][:casts] += 1
      self.kpi_hash[:vulnerable_ablities][ability_name][:damage] += event['amount'].to_i
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::FOCUS
      focus_waste = [@focus + event['resourceChange'].to_i - self.max_focus, 0].max
      focus_gain = event['resourceChange'].to_i - focus_waste
      @focus += focus_gain
      self.resources_hash[:focus_gain] += focus_gain
      self.resources_hash[:focus_waste] += focus_waste
      self.resources_hash[:focus_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:focus_abilities][ability_name][:gain] += focus_gain
      self.resources_hash[:focus_abilities][ability_name][:waste] += focus_waste
    end
  end

  def apply_debuff_event(event, refresh=false)
    super
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Vulnerable'
      if @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:early]
        # This was an early refresh, so record to penalize
        began_cast = @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:began_cast].to_i
        unless @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_aimed].nil? && @vuln_hits.include?(began_cast)
          # but only if there were hits, or no other vuln started at the same time had hits
          self.kpi_hash[:vulnerable_count] += 1
          last_aimed = @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_aimed] || 'No Cast'
          self.kpi_hash[:patient_sniper_casts][last_aimed] += 1 unless !self.kpi_hash[:patient_sniper_casts].has_key?(last_aimed)
          # only penalize one, if there were multiple started with the same cast
          @vuln_hits << began_cast
        end
      end
      @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_applied] = event['timestamp']
      @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_aimed] = nil
      @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:early] = false
      @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:trueshot] = is_active?('Trueshot', event['timestamp'])
      # save which cast started this vuln
      @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:began_cast] = @last_cast
    end
  end

  def remove_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    return if !@debuffs['Vulnerable'].has_key?(target_key)
    if ability_name == 'Vulnerable' && !is_active?('Trueshot', event['timestamp']) && !@debuffs['Vulnerable'][target_key][:dp].kpi_hash[:trueshot]
      # only record this if trueshot wasn't active
      if !refresh && event['timestamp'] - @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_applied].to_i < self.vuln_duration
        # Record that the vuln expired early. 
        # Assume add death, but if it is applied again, we will mark is as an early refresh
        @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:early] = true
      else
        began_cast = @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:began_cast] rescue 0
        unless @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_aimed].nil? && @vuln_hits.include?(began_cast)
          # ignore this one if there were no hits, but another vuln started at the same time did have hits
          self.kpi_hash[:vulnerable_count] += 1
          # mark when the last aimed shot happened
          last_aimed = @debuffs['Vulnerable'][target_key][:dp].kpi_hash[:last_aimed] || 'No Cast'
          self.kpi_hash[:patient_sniper_casts][last_aimed] += 1 unless !self.kpi_hash[:patient_sniper_casts].has_key?(last_aimed)
        end
      end
    end
  end

  def clean
    super
    focus_regen = (self.fight_time * (10 / self.haste_reduction_ratio)).to_i
    regen_wasted = (self.resources_hash[:capped_time].to_i * (10 / self.haste_reduction_ratio)).to_i
    self.resources_hash[:focus_gain] += focus_regen
    self.resources_hash[:focus_waste] += regen_wasted
    self.resources_hash[:focus_abilities]['Passive Gain'] = {name: 'Passive Gain', gain: focus_regen - regen_wasted, waste: regen_wasted}
    # recalculate score since aimed shot data is now complete
    score = max_score = 0
    self.track_casts.each do |spell, hash|
      next if self.casts_hash[spell].size == 0 && hash[:optional]
      unless hash[:cd].nil?
        max = casts_possible(hash).to_i * hash[:cd].to_i
        max_score += max
        score += [self.casts_hash[spell].size * hash[:cd].to_i, max].min
      end
    end
    max_score = score if score > max_score
    self.kpi_hash[:casts_score] = [100, 100 * score / max_score].min rescue 0
    
    self.debuff_parses.where(name: 'Vulnerable').each do |debuff|
      self.resources_hash[:vulnerable_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:vulnerable_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.cooldowns_hash[:trueshot_damage] = @kpis['Trueshot'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldown_parses.where(name: 'Bullseye x30').each do |bullseye|
      self.cooldowns_hash[:bullseye_damage] += bullseye.kpi_hash[:damage_done].to_i
      self.cooldowns_hash[:bullseye_uptime] += (bullseye.ended_at - bullseye.started_at rescue 0)
    end
    self.save
  end

end