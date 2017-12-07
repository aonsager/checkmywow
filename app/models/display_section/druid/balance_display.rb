class DisplaySection::Druid::BalanceDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        moonfire,
        sunfire,
        stellar_flare,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_cap('Astral Power'),
        resource_gain('Astral Power'),
        lunar_empowerment,
        solar_empowerment,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        starfall,
        force_of_nature,
        incarnation,
        celestial,
        fury_of_elune,
      ]
    end
  end

  def self.moonfire
    uptime = @fp.resources_hash[:moonfire_uptime].to_i
    data = debuff_graphs('Moonfire', :moonfire, {no_score: true})
    data[:hash][:desc] += " Enemies who were alive for less than 10 seconds are ignored."
    return data
  end

  def self.sunfire
    uptime = @fp.resources_hash[:sunfire_uptime].to_i
    data = debuff_graphs('Sunfire', :sunfire, {no_score: true})
    data[:hash][:desc] += " Enemies who were alive for less than 10 seconds are ignored."
    return data
  end

  def self.stellar_flare
    return false if @fp.talent(4) != 'Stellar Flare'
    uptime = @fp.resources_hash[:stellar_uptime].to_i
    data = debuff_graphs('Stellar Flare', :stellar, {no_score: true})
    data[:hash][:desc] += " Enemies who were alive for less than 10 seconds are ignored."
    return data
  end

  def self.lunar_empowerment
    data = proc_table('Lunar Empowerment', @fp.resources_hash[:lunar_used].to_i, @fp.resources_hash[:lunar_gained].to_i, ['Timestamp', 'Event'], @fp.resources_hash[:lunar_fails])
    data[:hash][:desc] = 'This section show how well you used your Lunar Empowerment procs. Be sure that you don\'t cast Starsurge while at 3 stacks.'
    return data
  end

  def self.solar_empowerment
    data = proc_table('Solar Empowerment', @fp.resources_hash[:solar_used].to_i, @fp.resources_hash[:solar_gained].to_i, ['Timestamp', 'Event'], @fp.resources_hash[:solar_fails])
    data[:hash][:desc] = 'This section show how well you used your Solar Empowerment procs. Be sure that you don\'t cast Starsurge while at 3 stacks.'
    return data
  end

  def self.starfall
    return false if @fp.cooldowns_hash[:starfall_damage].to_i == 0
    data = cooldown_dps('Starfall', :starfall_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    data[:hash][:desc] += ' The 20% increased damage from DoTs is shown in a lighter color.'
    return data
  end

  def self.force_of_nature
    return false if @fp.talent(0) != 'Force of Nature'
    data = cooldown_dps('Force of Nature', :force_damage, ['Ability', 'Casts', 'Damage Done'], [:name, :hits, :damage])
    data[:hash][:desc] = 'The total amount of damage dealt by your treants.'
    return data
  end

  def self.incarnation
    return false if @fp.talent(4) != 'Incarnation: Chosen of Elune'
    return cooldown_dps('Incarnation: Chosen of Elune', :incarnation_damage, ['Ability', 'Casts', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.celestial
    return false if @fp.talent(4) == 'Incarnation: Chosen of Elune'
    return cooldown_dps('Celestial Alignment', :celestial_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.fury_of_elune
    return false if @fp.talent(6) != 'Fury of Elune'
    return cooldown_dps('Fury of Elune', :fury_damage, ['Ability', 'Casts', 'Damage Done'], [:name, :hits, :damage])
  end

end