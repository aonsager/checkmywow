class FightParse::Mage::Fire < FightParse
  include Filterable
  self.table_name = :fp_mage_fire

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
      heating_up: 0,
      hot_streak: 0,
      hot_casts: {}
    }
    self.resources_hash = {

    }
    self.cooldowns_hash = {
      combustion_damage: 0,
      phoenix_damage: 0,
    }
    @check_abc = true
    @crit = nil
    @not_crit = nil
    self.save
  end

  # settings

  def track_casts
    local = {
      'Combustion' => {cd: 180},
      'Phoenix\'s Flames' => {cd: 45, extra: 2},
      'Fire Blast' => {cd: 12, extra: 1},
    }
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Combustion'] = {cd: 180}
    return bars
  end

  def uptime_abilities
    return {
      'Heating Up' => {},
      'Hot Streak!' => {},
    }
  end

  def cooldown_abilities
    local = {
      'Combustion' => {kpi_hash: {damage_done: 0}},
      'Phoenix\'s Flames' => {kpi_hash: {damage_done: 0}},
    }
    return super.merge local
  end

  def dps_abilities
    local = {
      'Phoenix\'s Flames' => {},
    }
    return super.merge local
  end

  def dps_buff_abilities
    local = {
      'Combustion' => {},
    }
    return super.merge local
  end

  def self.latest_version
    return super * 1000 + 2
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  def in_progress?
    return true
  end

  # getters

  def spell_name(id)
    return {
      133 => 'Fireball',
      2948 => 'Scorch',
      108853 => 'Fire Blast',
      48107 => 'Heating Up',
      48108 => 'Hot Streak!',
      190319 => 'Combustion',
      194466 => 'Phoenix\'s Flames',
    }[id] || super(id)
  end

  def hot_spells
    return [
      'Fireball',
      'Fire Blast',
      'Pyroblast',
      'Scorch',
      'Phoenix\'s Flames',
    ]
  end

  def max_cooldown
    return [self.cooldowns_hash[:combustion_damage]].max
  end

  # event handlers
  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if @uptimes['Heating Up'][:active] && hot_spells.include?(ability_name)
      if event['hitType'] == 1
        @not_crit ||= ability_name
      elsif event['hitType'] == 2
        @crit ||= ability_name
      end
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Heating Up'
      self.kpi_hash[:heating_up] += 1
      @crit = nil
    end
    if ability_name == 'Hot Streak!'
      self.kpi_hash[:hot_streak] += 1
      @crit ||= 'Unknown Spell'
      self.kpi_hash[:hot_casts][@crit] ||= {crits: 0, hits: 0}
      self.kpi_hash[:hot_casts][@crit][:hits] += 1
      self.kpi_hash[:hot_casts][@crit][:crits] += 1
    end
  end

  def lose_self_buff_event(event, force=true)
    super
    ability_name = spell_name(event['ability']['guid'])
    if ability_name == 'Heating Up'
      if !@uptimes['Hot Streak!'][:active]
        @not_crit ||= 'No Spell'
        self.kpi_hash[:hot_casts][@not_crit] ||= {crits: 0, hits: 0}
        self.kpi_hash[:hot_casts][@not_crit][:hits] += 1
      end
    end
  end

  def clean
    super
    self.cooldowns_hash[:combustion_damage] = @kpis['Combustion'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:phoenix_damage] = @kpis['Phoenix\'s Flames'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.save
  end

end