class DisplaySection::Shaman::EnhancementDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        landslide,
        fury_of_air,
        frostbrand,
        flametongue,
        lightning_crash,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_cap('Maelstrom'),
        maelstrom_damage,
        stormbringer_procs,
        hothand_procs,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        cooldown_dps('Doom Winds', :doomwinds_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        cooldown_dps('Feral Spirit', :feral_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        ascendance,
      ]
    end
  end

  def self.landslide
    return false if @fp.talent(0) != 'Landslide'
    uptime = @fp.resources_hash[:landslide_uptime].to_i
    score = 100 * uptime / (@fp.ended_at - @fp.started_at)
    return buff_stacks_graph('Landslide', uptime, score)
  end

  def self.fury_of_air
    return false if @fp.talent(5) != 'Fury of Air'
    uptime = @fp.resources_hash[:fury_of_air_uptime].to_i
    score = 100 * uptime / (@fp.ended_at - @fp.started_at)
    return buff_stacks_graph('Fury of Air', uptime, score)
  end

  def self.frostbrand
    return false if @fp.talent(3) != 'Hailstorm'
    uptime = @fp.resources_hash[:frostbrand_uptime].to_i
    score = 100 * uptime / (@fp.ended_at - @fp.started_at)
    return buff_stacks_graph('Frostbrand', uptime, score)
  end

  def self.flametongue
    uptime = @fp.resources_hash[:flametongue_uptime].to_i
    score = 100 * uptime / (@fp.ended_at - @fp.started_at)
    return buff_stacks_graph('Flametongue', uptime, score)
  end

  def self.lightning_crash
    return false if @fp.set_bonus(20) < 2
    uptime = @fp.resources_hash[:lightning_crash_uptime].to_i
    return buff_stacks_graph('Lightning Crash', uptime)
  end
  
  def self.casts
    data = super
    data[:hash][:desc] += " Your haste reduced cooldowns of Stormstrike and Rockbiter by #{@fp.haste_reduction_percent.round(2)}%."
    return data
  end

  def self.maelstrom_damage
    hash = {
      title: 'Maelstrom Usage',
      desc: 'The amount of damage per Maelstrom you did with each ability. Spells are ordered by total Maelstrom spent. Try to spend Maelstrom on high-damage abilities as much as possible.',
      main_bar_width: 100,
      main_bar_text: "#{@fp.resources_hash[:maelstrom_damage].to_i / @fp.resources_hash[:maelstrom_spent].to_i rescue 0} dmg/Maelstrom",
      main_text: "#{@fp.resources_hash[:maelstrom_damage].to_i / @fp.resources_hash[:maelstrom_spent].to_i rescue 0} damage per Maelstrom",
    }
    return {hash: hash} if @boss

    bar_key = 'dpm-w'
    hash[:sub_bars] = @fp.resources_hash[:maelstrom_spend].nil? ? nil :@fp.resources_hash[:maelstrom_spend].values.sort{|a, b| b[:spent].to_i <=> a[:spent].to_i }.map{|item| 
      {
        label: item[:name],
        val: 1000 * item[:damage].to_i / item[:spent].to_i,
        bar_key: bar_key,
        text: "#{item[:damage].to_i / item[:spent].to_i} dpm",
        sub_text: "#{number_to_human(item[:damage].to_i)} damage / #{item[:spent].to_i} Maelstrom",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.stormbringer_procs
    return proc_usage('Stormbringer', @fp.kpi_hash[:stormbringer_used].to_i, @fp.kpi_hash[:stormbringer_procs].to_i)
  end

  def self.hothand_procs
    return false if @fp.talent(0) != 'Hot Hand'
    return proc_usage('Hot Hand', @fp.kpi_hash[:hothand_used].to_i, @fp.kpi_hash[:hothand_procs].to_i)
  end

  def self.ascendance
    return false if @fp.talent(6) != 'Ascendance'
    return cooldown_dps('Ascendance', :ascendance_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

end