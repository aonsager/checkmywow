class FightParse::Rogue::Assassination < FightParse
  include Filterable
  self.table_name = :fp_rogue_sin

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      combo_gain: 0,
      combo_waste: 0,
      combo_abilities: {},
      combo_spend: {},
      rupture_uptime: 0,
      rupture_downtime: 0,
      surge_uptime: 0,
      surge_downtime: 0,
      garrote_uptime: 0,
      garrote_downtime: 0,
      poison_uptime: 0,
      poison_downtime: 0,
    }
    self.cooldowns_hash = {
      vendetta_damage: 0,
      vendetta_extra_damage: 0,
      kingsbane_damage: 0,
      stealth_bleed_details: [],
      good_vanish_bleeds: 0,
      bad_vanish_bleeds: 0,
      kingsbane_uptime: 0,
      kingsbane_envenom_uptime: 0,
    }
    @resources = {
      "r#{ResourceType::COMBOPOINTS}" => 0,
      "r#{ResourceType::COMBOPOINTS}_max" => self.max_combo,
    }
    @combo = 0
    @vanish_cast = nil
    @rupture_cps = 0
    @garrote_cps = 0
    self.save
  end

  # settings

  def self.latest_version
    return super * 1000 + 3
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  # getters

  def spell_name(id)
    return {
      1943 => 'Rupture',
      703 => 'Garrote',
      2823 => 'Deadly Poison',
      2818 => 'Deadly Poison',
      200802 => 'Agonizing Poison',
      200803 => 'Agonizing Poison',
      79140 => 'Vendetta',
      192432 => 'Vendetta', # actually From the Shadows
      192434 => 'Vendetta', # actually From the Shadows
      192759 => 'Kingsbane',
      192349 => 'Master Assassin',
      193531 => 'Deeper Stratagem',
      193640 => 'Elaborate Planning',
      193641 => 'Elaborate Planning',
      32645 => 'Envenom',
      1784 => 'Stealth',
      1856 => 'Vanish',
      14062 => 'Nightstalker',
      108208 => 'Subterfuge',
      192425 => 'Surge of Toxins',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Vanish'] = {cd: 120}
    local['Vendetta'] = {cd: self.vendetta_cd}
    local['Kingsbane'] = {cd: 45}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Nightstalker'] = {} if talent(1) == 'Nightstalker'
    bars['cd']['Subterfuge'] = {} if talent(1) == 'Subterfuge'
    bars['cd']['Vendetta'] = {cd: self.vendetta_cd}
    bars['cd']['Kingsbane'] = {cd: 45}
    bars['cd']['Elaborate Planning'] = {} if talent(0) == 'Elaborate Planning'
    return bars
  end

  def cooldown_abilities
    local = {
      'Nightstalker' => {kpi_hash: {damage_done: 0}},
      'Subterfuge' => {kpi_hash: {damage_done: 0}},
      'Vendetta' => {kpi_hash: {damage_done: 0}},
      'Kingsbane' => {kpi_hash: {damage_done: 0}},
      'Elaborate Planning' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Kingsbane' => {},
      'Vendetta' => {piggyback: 'Vendetta'}, # to mark From the Shadows as extra damage
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Rupture' => {},
      'Garrote' => {},
      'Deadly Poison' => {},
      'Agonizing Poison' => {},
      'Vendetta' => {},
      'Kingsbane' => {},
      'Surge of Toxins' => {},
    }
    return local.merge super
  end

  def buff_abilities
    local = {
      'Envenom' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::COMBOPOINTS]
  end

  def show_resources
    return [ResourceType::ENERGY, ResourceType::COMBOPOINTS]
  end

  def max_combo
    if talent(2) == 'Deeper Stratagem'
      return 6
    else
      return 5
    end
  end

  def cp_hash
    if talent(2) == 'Deeper Stratagem'
      {1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0}
    else
      {1=>0, 2=>0, 3=>0, 4=>0, 5=>0}
    end
  end

  def vendetta_cd
    return 120 - artifact('Master Assassin').to_i * 10
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Vanish'
      @vanish_cast = nil
      self.cooldowns_hash[:stealth_bleed_details] << {timestamp: event['timestamp'], msg: 'Cast Vanish'}
    elsif @vanish_cast == nil && ability_name != 'Melee'
      @vanish_cast = ability_name
      self.cooldowns_hash[:stealth_bleed_details] << {timestamp: event['timestamp'], class: 'red', msg: "Cast #{ability_name}"}
    end 
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::ENERGY
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
      end
      if resource['type'] == ResourceType::COMBOPOINTS
        if resource['cost'].to_i > 0 && event['timestamp'] - self.started_at > 5000 # ignore first 5 seconds
          self.resources_hash[:combo_spend][ability_name] ||= {name: ability_name, combo: cp_hash}

          self.resources_hash[:combo_spend][ability_name][:combo][@combo] += 1 unless @combo == 0
        end
        @combo = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        @rupture_cps = resource['cost'] if ability_name == 'Rupture'
        @garrote_cps = resource['cost'] if ability_name == 'Garrote'
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::COMBOPOINTS
      combo_waste = [@combo + event['resourceChange'].to_i - self.max_combo, 0].max
      combo_gain = event['resourceChange'].to_i - combo_waste
      @combo += combo_gain
      if ability_name != 'Seal Fate'
        self.resources_hash[:combo_gain] += combo_gain
        self.resources_hash[:combo_waste] += combo_waste
      end
      self.resources_hash[:combo_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:combo_abilities][ability_name][:gain] += combo_gain
      self.resources_hash[:combo_abilities][ability_name][:waste] += combo_waste
    end
  end

  def deal_damage_event(event)
    super
    return if event['amount'].to_i == 0
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if @debuffs['Vendetta'].has_key?(target_key) && @debuffs['Vendetta'][target_key][:active]
      cp = @cooldowns['Vendetta'][:cp]
      amount = (event['amount'].to_i * 0.3).to_i
      cp.kpi_hash[:damage_done] = cp.kpi_hash[:damage_done].to_i + amount
      cp.details_hash[ability_name] ||= {name: ability_name, damage: 0, hits: 0}
      cp.details_hash[ability_name][:damage] += amount
      cp.details_hash[ability_name][:hits] += 1
    end
  end

  def lose_self_buff_event(event, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    @vanish_cast = nil if ability_name == 'Stealth'
  end

  def apply_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"

    if ability_name == 'Vendetta'
      gain_cooldown('Vendetta', event['timestamp'], {})
    elsif ability_name == 'Rupture' || ability_name == 'Garrote'
      if talent(1) == 'Nightstalker'
        buff_name = 'Nightstalker'
      elsif talent(1) == 'Subterfuge' && ability_name == 'Garrote'
        buff_name = 'Subterfuge'
      else
        buff_name = nil
      end
      cps = ability_name == 'Rupture' ? @rupture_cps : @garrote_cps
      cps = @combo if @combo != 0 # sometimes the debuff comes before cast event
      @debuffs[ability_name][target_key][:dp].kpi_hash[:cps] = cps
      if ability_name == 'Rupture'
        @debuffs[ability_name][target_key][:dp].kpi_hash[:length] = 4000 * (cps + 1)
      else # garrote
        @debuffs[ability_name][target_key][:dp].kpi_hash[:length] = 18000
      end
      pandemic_bonus = [@debuffs[ability_name][target_key][:dp].kpi_hash[:pandemic].to_i, @debuffs[ability_name][target_key][:dp].kpi_hash[:length] / 3.0].min
      @debuffs[ability_name][target_key][:dp].kpi_hash[:length] += pandemic_bonus
      @debuffs[ability_name][target_key][:dp].kpi_hash[:estimated_end] = (event['timestamp'] + @debuffs[ability_name][target_key][:dp].kpi_hash[:length]).to_i
      
      if (@vanish_cast == ability_name || @vanish_cast.nil?) && (!buff_name.nil? && talent(1) == buff_name)
        # mark this bleed as being buffed by stealth
        @debuffs[ability_name][target_key][:dp].kpi_hash[:vanish] = true
        gain_cooldown(buff_name, event['timestamp'], {})
        if cps == self.max_combo
          color = 'green'
          self.cooldowns_hash[:good_vanish_bleeds] += 1
        else
          color = 'red'
          self.cooldowns_hash[:bad_vanish_bleeds] += 1
        end
        # overwrite the cast
        self.cooldowns_hash[:stealth_bleed_details].pop
        self.cooldowns_hash[:stealth_bleed_details] << {timestamp: event['timestamp'], class: color, msg: "#{cps}CP #{ability_name} applied from stealth (#{@debuffs[ability_name][target_key][:dp].kpi_hash[:length] / 1000}s)"}
        @vanish_cast = 'expired'
      end
    end
  end

  def remove_debuff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if ability_name == 'Vendetta'
      drop_cooldown('Vendetta', event['timestamp'])
    elsif (['Rupture', 'Garrote'].include?(ability_name) && is_active?('Nightstalker', event['timestamp'])) || (ability_name == 'Garrote' && is_active?('Subterfuge', event['timestamp']))
      # check if the bleed was buffed
      if refresh
        early = ((@debuffs[ability_name][target_key][:dp].kpi_hash[:estimated_end] - event['timestamp']) * 0.001).round(2)
        self.cooldowns_hash[:stealth_bleed_details] << {timestamp: event['timestamp'], class: 'red', msg: "#{ability_name} refreshed #{early}s early"}
        self.cooldowns_hash[:bad_vanish_bleeds] += 1
      else
        self.cooldowns_hash[:stealth_bleed_details] << {timestamp: event['timestamp'], class: 'green', msg: "#{ability_name} ticked fully"}
        self.cooldowns_hash[:good_vanish_bleeds] += 1
      end
      drop_cooldown(talent(1), event['timestamp'])
    end
  end

  def clean
    super

    self.resources_hash[:garrote_uptime] = @uptimes['Garrote'][:uptime] rescue 0
    self.debuff_parses.where(name: 'Rupture').each do |debuff|
      self.resources_hash[:rupture_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:rupture_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.debuff_parses.where(name: 'Surge of Toxins').each do |debuff|
      self.resources_hash[:surge_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:surge_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    if talent(5) == 'Agonizing Poison'
      self.debuff_parses.where(name: 'Agonizing Poison').each do |debuff|
        self.resources_hash[:poison_uptime] += debuff.kpi_hash[:uptime].to_i
        self.resources_hash[:poison_downtime] += debuff.kpi_hash[:downtime].to_i
      end
    else
      self.debuff_parses.where(name: 'Deadly Poison').each do |debuff|
        self.resources_hash[:poison_uptime] += debuff.kpi_hash[:uptime].to_i
        self.resources_hash[:poison_downtime] += debuff.kpi_hash[:downtime].to_i
      end
    end
    self.cooldowns_hash[:vendetta_damage] = @kpis['Vendetta'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldowns_hash[:vendetta_extra_damage] = @kpis['Vendetta'].map{|kpi| kpi[:extra_damage].to_i}.sum rescue 0
    self.cooldowns_hash[:kingsbane_damage] = @kpis['Kingsbane'].map{|kpi| kpi[:damage_done].to_i}.sum rescue 0
    self.cooldown_parses.where(name: 'Kingsbane').each do |kingsbane|
      self.cooldowns_hash[:kingsbane_uptime] += (kingsbane.ended_at - kingsbane.started_at rescue 0)
      envenom_uptime = @buffs['Envenom'][:bp].uptime_range(kingsbane.started_at, kingsbane.ended_at) rescue 0
      self.cooldowns_hash[:kingsbane_envenom_uptime] += envenom_uptime
      kingsbane.kpi_hash[:uptime] = kingsbane.ended_at - kingsbane.started_at rescue 0
      kingsbane.kpi_hash[:envenom_uptime] = envenom_uptime
      kingsbane.save!
    end
    self.save
  end

end