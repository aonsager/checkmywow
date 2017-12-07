class FightParse::Mage::Frost < FightParse
  include Filterable
  self.table_name = :fp_mage_frost

  def self.latest_patch
    return '7.2.5'
  end

  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
      brain_freeze_used: 0,
      brain_freeze_procs: 0,
      brain_freeze_waste_details: [],
      winters_chill_used: 0,
      winters_chill_procs: 0,
      winters_chill_waste_details: [],
      fingers_gained: 0,
      fingers_wasted: 0,
      fingers_waste_details: []
    }
    self.resources_hash = {
      frozen_orb_cdr: 0,
    }
    self.cooldowns_hash = {
      rune_of_power_damage: 0,
      mirror_image_damage: 0,
      icy_veins_damage: 0,
      frozen_orb_damage: 0,
      ray_of_frost_damage: 0,
    }
    @check_abc = true

    self.save
  end

  # settings

  def max_fingers
    return artifact('Icy Hand') ? 3 : 2
  end

  SET_IDS = {
    20 => [147145, 147146, 147147, 147148, 147149, 147150],
  }

  def spell_name(id)
    return {
      116011 => 'Rune of Power',
      55342 => 'Mirror Image',
      12472 => 'Icy Veins',
      84714 => 'Frozen Orb',
      205021 => 'Ray of Frost',
      214634 => 'Ebonbolt',
      153595 => 'Comet Storm',
      190446 => 'Brain Freeze',
      190447 => 'Brain Freeze',
      44544 => 'Fingers of Frost',
      112965 => 'Fingers of Frost',
      30455 => 'Ice Lance',
      112948 => 'Ice Lance',
      228598 => 'Ice Lance',
      44614 => 'Flurry',
      135029 => 'Water Jet',
      228358 => 'Winter\'s Chill',
      220817 => 'Icy Hand',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Icy Veins'] = {cd: 180}
    local['Mirror Image'] = {cd: 120} if talent(2) == 'Mirror Image'
    local['Ray of Frost'] = {cd: 60} if talent(0) == 'Ray of Frost'
    local['Frozen Orb'] = {cd: 60, reduction: self.resources_hash[:frozen_orb_cdr].to_i}
    local['Ebonbolt'] = {cd: 45}
    local['Rune of Power'] = {cd: 40, extra: 1} if talent(2) == 'Rune of Power'
    
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Icy Veins'] = {cd: 180}
    bars['cd']['Mirror Image'] = {cd: 120} if talent(2) == 'Mirror Image'
    bars['cd']['Rune of Power'] = {cd: 40, extra: 1} if talent(2) == 'Rune of Power'
    return bars
  end

  def uptime_abilities
    return {
      'Brain Freeze' => {},
    }
  end

  def buff_abilities
    local = {
      'Fingers of Frost' => {target_stacks: max_fingers},
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Winter\'s Chill' => {},
    }
    return super.merge local
  end

  def cooldown_abilities
    local = {
      'Rune of Power' => {kpi_hash: {damage_done: 0}},
      'Mirror Image' => {kpi_hash: {damage_done: 0}},
      'Icy Veins' => {kpi_hash: {damage_done: 0}},
      'Frozen Orb' => {kpi_hash: {damage_done: 0}},
      'Ray of Frost' => {kpi_hash: {damage_done: 0, extra_damage: 0}},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Rune of Power' => {},
      'Mirror Image' => {},
      'Icy Veins' => {},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Frozen Orb' => {},
      'Ray of Frost' => {channel: true},
    }
    return super.merge local
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Flurry' && @uptimes['Brain Freeze'][:active]
      self.kpi_hash[:brain_freeze_used] += 1
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Ice Lance'
      if (@debuffs['Winter\'s Chill'][target_key][:active] rescue false)
        @debuffs['Winter\'s Chill'][target_key][:dp].kpi_hash[:ice_lances] += 1
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Brain Freeze'
      self.kpi_hash[:brain_freeze_procs] += 1
      self.kpi_hash[:brain_freeze_waste_details] << {timestamp: event['timestamp'], msg: "Overwrote Brain Freeze"} if refresh
      self.resources_hash[:frozen_orb_cdr] += 5 if set_bonus(20) >= 4
    elsif ability_name == 'Fingers of Frost'
      self.kpi_hash[:fingers_gained] += 1
    end
  end

  def gain_self_buff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    # check if already at max fingers of frost
    if ability_name == 'Fingers of Frost'
      self.kpi_hash[:fingers_gained] += 1
      if (@buffs['Fingers of Frost'][:bp].stacks_array.last[:stacks] rescue 0) == max_fingers
        self.kpi_hash[:fingers_wasted] += 1
        self.kpi_hash[:fingers_waste_details] << {timestamp: event['timestamp'], msg: "Gained Fingers of Frost while at max stacks"}
      end
    end

    super
    
  end

  def apply_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    # ignore repeated applications
    if ability_name == 'Winter\'s Chill' && !refresh
      # check for unused fingers of frost
      stacks = @buffs['Fingers of Frost'][:bp].stacks_array.last[:stacks] rescue 0
      if stacks > 0
        self.kpi_hash[:fingers_wasted] += stacks
        self.kpi_hash[:fingers_waste_details] << {timestamp: event['timestamp'], msg: "Applied Winter's Chill with #{stacks} Fingers of Frost"}
      end
      # mark winter's chill proc
      self.kpi_hash[:winters_chill_procs] += 1
      @debuffs['Winter\'s Chill'][target_key][:dp].kpi_hash[:ice_lances] = 0
    end
  end

  def remove_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Winter\'s Chill' && !refresh
      debuff = @debuffs['Winter\'s Chill'][target_key][:dp]
      if debuff.kpi_hash[:ice_lances] == 0
        self.kpi_hash[:winters_chill_waste_details] << {timestamp: debuff.uptimes_array.last[:started_at], msg: "Winter's Chill applied to #{@actors[event['targetID']]} was unused"}
      else
        self.kpi_hash[:winters_chill_used] += 1
      end
    end
  end
  
  def clean
    super
    aggregate_dps_cooldowns
    self.save
  end

end