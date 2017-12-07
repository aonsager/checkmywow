class FightParse::Druid::Feral < FightParse
  include Filterable
  self.table_name = :fp_druid_feral

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
      rip_uptime: 0,
      rake_uptime: 0,
      rake_downtime: 0,
    }
    self.cooldowns_hash = {

    }
    @resources = {
      "r#{ResourceType::COMBOPOINTS}" => 0,
      "r#{ResourceType::COMBOPOINTS}_max" => self.max_combo,
    }
    @combo = 0
    self.save
  end

  # settings

  def self.latest_version
    return super * 1000 + 1
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  # getters

  def spell_name(id)
    return {
      210723 => 'Ashamane\'s Frenzy',
      210722 => 'Ashamane\'s Frenzy',
      1822 => 'Rake',
      155722 => 'Rake',
      1079 => 'Rip',
      5217 => 'Tiger\'s Fury',
      106951 => 'Berserk',
      102543 => 'Incarnation: King of the Jungle',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    if talent(4) == 'Incarnation: King of the Jungle'
      local['Incarnation: King of the Jungle'] = {cd: 180}
    else
      local['Berserk'] = {cd: 180}
    end
    local['Ashamane\'s Frenzy'] = {cd: 75}
    local['Tiger\'s Fury'] = {cd: 30}

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    if talent(4) == 'Incarnation: King of the Jungle'
      bars['cd']['Incarnation: King of the Jungle'] = {cd: 180}
    else
      bars['cd']['Berserk'] = {cd: 180}
    end
    bars['cd']['Berserk'] = {cd: 180}
    bars['cd']['Tiger\'s Fury'] = {cd: 30}

    return bars
  end

  def debuff_abilities
    local = {
      'Rip' => {},
      'Rake' => {},
    }
    return local.merge super
  end

  def track_resources
    return [ResourceType::COMBOPOINTS]
  end

  def show_resources
    return [ResourceType::ENERGY, ResourceType::COMBOPOINTS]
  end

  def max_combo
    return 5
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
  
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::ENERGY
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
      end
      if resource['type'] == ResourceType::COMBOPOINTS
        if resource['cost'].to_i > 0
          self.resources_hash[:combo_spend][ability_name] ||= {name: ability_name, combo: {1=>0, 2=>0, 3=>0, 4=>0, 5=>0}}
          self.resources_hash[:combo_spend][ability_name][:combo][@combo] += 1 unless @combo == 0
        end
        @combo = [resource['amount'].to_i - resource['cost'].to_i, 0].max
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
      self.resources_hash[:combo_gain] += combo_gain
      self.resources_hash[:combo_waste] += combo_waste
      self.resources_hash[:combo_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:combo_abilities][ability_name][:gain] += combo_gain
      self.resources_hash[:combo_abilities][ability_name][:waste] += combo_waste
    end
  end

  def clean
    super

    self.resources_hash[:rip_uptime] = @uptimes['Rip'][:uptime] rescue 0
    self.debuff_parses.where(name: 'Rake').each do |debuff|
      self.resources_hash[:rake_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:rake_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.save
  end

end