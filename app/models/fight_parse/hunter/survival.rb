class FightParse::Hunter::Survival < FightParse
  include Filterable
  self.table_name = :fp_hunter_survival

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      moknathal_uptime: 0,
      lacerate_uptime: 0,
      eagle_stacks: {0=>0, 1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0}
    }
    self.resources_hash = {
      capped_time: 0,
      focus_gain: 0,
      focus_waste: 0,
      focus_abilities: {},
    }
    self.cooldowns_hash = {

    }
    @focus = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      191433 => 'Explosive Trap',
      194855 => 'Dragonsfire Grenade',
      206505 => 'A Murder of Crows',
      202800 => 'Flanking Strike',
      194407 => 'Spitting Cobra',
      200163 => 'Throwing Axes',
      203415 => 'Fury of the Eagle',
      201082 => 'Way of the Mok\'Nathal',
      201081 => 'Mok\'Nathal Tactics',
      185855 => 'Lacerate',
      190931 => 'Mongoose Fury',
      190928 => 'Mongoose Bite',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['A Murder of Crows'] = {cd: 60} if talent(1) == 'A Murder of Crows'
    local['Spitting Cobra'] = {cd: 60} if talent(6) == 'Spitting Cobra'
    local['Fury of the Eagle'] = {cd: 45}
    local['Explosive Trap'] = {cd: 30}
    local['Dragonsfire Grenade'] = {cd: 30} if talent(5) == 'Dragonsfire Grenade'
    local['Throwing Axes'] = {cd: 15, extra: 1} if talent(0) == 'Throwing Axes'
    # local['Mongoose Bite'] = {cd: 12 * self.haste_reduction_ratio, extra: 2}
    # local['Flanking Strike'] = {cd: 6 }
    
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super

    return bars
  end

  def buff_abilities
    local = {
      'Mok\'Nathal Tactics' => {target_stacks: 4},
      'Mongoose Fury' => {target_stacks: 6},
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Lacerate' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::FOCUS]
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def in_progress?
    return true
  end

  # getters

  def max_focus
    return 100
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if ability_name == 'Fury of the Eagle' && !@buffs['Mongoose Fury'][:bp].nil? && @buffs['Mongoose Fury'][:bp].stacks_array.count > 0
      self.kpi_hash[:eagle_stacks][@buffs['Mongoose Fury'][:bp].stacks_array.last[:stacks].to_i] += 1
    end
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::FOCUS
        @focus = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
      end
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

  def clean
    super
    self.kpi_hash[:moknathal_uptime] = @kpis['Mok\'Nathal Tactics'].first[:stacks_uptime].to_i unless @kpis['Mok\'Nathal Tactics'].nil?
    self.resources_hash[:lacerate_uptime] = @uptimes['Lacerate'][:uptime] rescue 0
    self.save
  end

end