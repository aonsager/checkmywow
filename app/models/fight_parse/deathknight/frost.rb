class FightParse::Deathknight::Frost < FightParse
  include Filterable
  self.table_name = :fp_dk_frost

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
    }
    self.resources_hash = {
      rp_capped_time: 0,
      runes_capped_time: 0,
      rp_gain: 0,
      rp_waste: 0,
      rp_abilities: {},
      ff_uptime: 0,
      ff_downtime: 0,
    }
    self.cooldowns_hash = {
    }
    @resources = {
      "r#{ResourceType::RUNICPOWER}" => 0,
      "r#{ResourceType::RUNICPOWER}_max" => 100,
      "r#{ResourceType::RUNES}" => 0,
      "r#{ResourceType::RUNES}_max" => 6,
    }
    @runicpower = 0
    self.save
  end

  # settings

  def spell_name(id)
    return {
      51271 => 'Pillar of Frost',
      190778 => 'Sindragosa\'s Fury',
      49020 => 'Obliterate',
      57330 => 'Horn of Winter',
      47568 => 'Empowered Rune Weapon',
      207127 => 'Hungering Rune Weapon',
      152279 => 'Breath of Sindragosa',
      207256 => 'Obliteration',
      207126 => 'Icecap',
      194913 => 'Glacial Advance',
      55095 => 'Frost Fever',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Sindragosa\'s Fury'] = {cd: 300}
    if talent(2) == 'Hungering Rune Weapon'
      local['Hungering Rune Weapon'] = {cd: 180} 
    else
      local['Empowered Rune Weapon'] = {cd: 180} 
    end
    local['Breath of Sindragosa'] = {cd: 120} if talent(6) == 'Breath of Sindragosa'
    local['Obliteration'] = {cd: 90} if talent(6) == 'Obliteration'
    local['Pillar of Frost'] = {cd: 60}
    # local['Pillar of Frost'][:reduction] = self.pillar_reduction if talent(2) == 'Icecap'
    local['Horn of Winter'] = {cd: 30} if talent(1) == 'Horn of Winter'
    local['Glacial Advance'] = {cd: 15 * self.haste_reduction_ratio} if talent(6) == 'Glacial Advance'
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super

    return bars
  end


  def cooldown_abilities
    local = {

    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Frost Fever' => {},
    }
    return super.merge local
  end

  def track_resources
    return [ResourceType::RUNICPOWER]
  end

  def show_resources
    return [ResourceType::RUNICPOWER, ResourceType::RUNES]
  end

  def self.latest_version
    return super * 1000 + 1
  end

  def in_progress?
    return true
  end

  # getter

  def max_runicpower
    return 100
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']

    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::RUNICPOWER
        check_resource_cap(resource['amount'].to_i, resource['max'].to_i, event['timestamp'], 'rp')
        # self.resources_hash[:rp_spent] += resource['cost'].to_i / 10
        @runicpower = [resource['amount'].to_i - resource['cost'].to_i, 0].max / 10
      elsif resource['type'] == ResourceType::RUNES
        check_resource_cap(resource['amount'].to_i, resource['max'].to_i, event['timestamp'], 'runes')
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::RUNICPOWER
      runicpower_waste = [@runicpower + event['resourceChange'].to_i - self.max_runicpower, 0].max
      runicpower_gain = event['resourceChange'].to_i - runicpower_waste
      @runicpower += runicpower_gain
      self.resources_hash[:rp_gain] += runicpower_gain
      self.resources_hash[:rp_waste] += runicpower_waste
      self.resources_hash[:rp_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:rp_abilities][ability_name][:gain] += runicpower_gain
      self.resources_hash[:rp_abilities][ability_name][:waste] += runicpower_waste
    end
  end

  def clean
    super
    self.resources_hash[:rp_capped_time] = self.resources_hash[:rp_capped_time].to_i / 1000
    self.resources_hash[:runes_capped_time] = self.resources_hash[:runes_capped_time].to_i / 1000
    self.debuff_parses.where(name: 'Frost Fever').each do |debuff|
      self.resources_hash[:ff_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:ff_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.save
  end

end