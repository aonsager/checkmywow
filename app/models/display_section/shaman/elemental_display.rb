class DisplaySection::Shaman::ElementalDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        debuff_graphs('Flame Shock', :flameshock),
        lavaburst,
        totem_mastery,
        stormkeeper,
        ice_fury,
        chain_lightning,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_gain('Maelstrom'),
        maelstrom_damage,
        earthshock,
        abc,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        elementals,
        stormkeeper_damage,
        ascendance,
      ]
    end
  end

  def self.lavaburst
    data = proc_table('Lava Burst', @fp.kpi_hash[:lavaburst_good].to_i, @fp.kpi_hash[:lavaburst_casts].to_i, ['Time', 'Bad Cast'], @fp.kpi_hash[:lavaburst_badcasts])
    data[:hash][:desc] = "Every cast of Lava Burst should be on an enemy with Flame Shock active, to result in a guaranteed crit. This sections shows how many casts were on an enemy with an active Flame Shock."
    return data
  end

  def self.totem_mastery
    return false if @fp.talent(0) != 'Totem Mastery'
    return buff_stacks_graph('Totem Mastery', @fp.resources_hash[:totem_uptime].to_i, @fp.resources_hash[:totem_uptime].to_i / (10 * @fp.fight_time))
  end

  def self.stormkeeper
    data = proc_table('Stormkeeper', @fp.kpi_hash[:stormkeeper_buffed].to_i, @fp.kpi_hash[:stormkeeper_possible].to_i)
    data[:hash][:desc] = "You should take advantage of every Stormkeeper cast by making sure that 3 casts of Lightning Bolt / Chain Lightning are buffed each time. This section shows how many casts were buffed."
    return data
  end

  def self.ice_fury
    return false if @fp.talent(4) != 'Ice Fury'
    data = proc_table('Ice Fury', @fp.kpi_hash[:icefury_buffed].to_i, @fp.kpi_hash[:icefury_possible].to_i)
    data[:hash][:desc] = 'You should take advantage of every Ice Fury cast by making sure that 4 casts of Frost Shock are buffed each time. This section shows how many casts were buffed'
    return data
  end

  def self.chain_lightning
    return false if @fp.kpi_hash[:chainlightning_casts].to_i == 0
    data = proc_table('Chain Lightning', @fp.kpi_hash[:chainlightning_good].to_i, @fp.kpi_hash[:chainlightning_casts].to_i, ['Time', 'Bad Cast'], @fp.kpi_hash[:chainlightning_badcasts])
    data[:hash][:desc] = "You should never cast Chain Lightning if it will only hit one target. This section shows how many casts of hit at least 2 targets."
    return data
  end

  def self.maelstrom_damage
    hash = {
      title: 'Maelstrom Usage',
      desc: 'The amount of damage per Maelstrom you did with each ability. Spells are ordered by total Maelstrom spent. Try to spend Maelstrom on high-damage abilities as much as possible.',
      main_bar_width: 100,
      val: (@fp.resources_hash[:maelstrom_damage].to_i / @fp.resources_hash[:maelstrom_spent].to_i rescue 0),
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

  def self.earthshock
    data = proc_table('Earth Shock', @fp.resources_hash[:earthshock_good].to_i, @fp.resources_hash[:earthshock_good].to_i + @fp.resources_hash[:earthshock_bad].to_i, ['Time', 'Bad Cast'], @fp.resources_hash[:earthshock_casts])
    data[:hash][:title] = 'Earth Shock Usage'
    data[:hash][:desc] = 'You should only cast Earth Shock to prevent capping, if you have more than 117 Maelstrom. You should also try to cast it when Elemental Focus is active, if possible. This section shows how many casts matched this guideline.'
    return data
  end

  def self.elementals
    bar_key = 'elementals-w'
    hash = {
      title: 'Fire/Storm Elemental Effectiveness',
      desc: 'The total amount of damage you dealt with your Fire/Storm Elementals.',
      bar_key: 'cd-w',
      val: @fp.cooldowns_hash[:elemental_damage].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: "#{@fp.cooldowns_hash[:elemental_damage].to_i / 1000}k",
      main_text: "#{@fp.cooldowns_hash[:elemental_damage].to_i / 1000}k damage"
    } 
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(cd_type: 'pet', name: ['Greater Fire Elemental', 'Greater Storm Elemental', 'Primal Fire Elemental', 'Primal Storm Elemental'])
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i,
        text: number_to_human(item.kpi_hash[:damage_done].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:damage_done].to_i)} dmg / #{item.time} sec",
        dropdown: {
          id: "elemental-#{item.id}",
          headers: ['Enemy', 'Hits', 'Damage Done'],
          content: item.details_hash.map{|id, hash| [hash[:name], hash[:hits].to_i, hash[:damage].to_i]}
        }
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.stormkeeper_damage
    data = cooldown_dps('Stormkeeper', :stormkeeper_damage, ['Spell', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    data[:hash][:desc] = 'The total amount of damage you dealt with Lightning Bolt and Chain Lightning, while buffed with Stormkeeper.'
    return data
  end

  def self.ascendance
    return false if @fp.talent(6) != 'Ascendance'
    data = cooldown_dps('Ascendance', :ascendance_damage, ['Spell', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    data[:hash][:desc] = 'The total amount of damage you dealt with Lava Burst and Lava Beam while Ascendance was active.'
    return data
  end


end