class DisplaySection::Monk::WindwalkerDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        hitcombo,
        combostrikes,
        pressure_point,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_cap('Energy'),
        resource_gain('Chi'),
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        fists_of_fury,
        strike_of_the_windlord,
        spinning_crane_kick,
        xuen,
        serenity,
        storm_earth_fire,
        touch_of_death,
      ]
    end
  end
  
  def self.hitcombo
    uptime = @fp.kpi_hash[:hitcombo_uptime].to_i
    score = (100 / 0.95) * uptime / (@fp.ended_at - @fp.started_at)
    return buff_stacks_graph('Hit Combo', uptime, score)
  end

  def self.combostrikes
    return false if !@fp.kpi_hash.has_key?(:mastery) || !@fp.kpi_hash[:mastery].has_key?(:fail_details)
    good_casts = @fp.kpi_hash[:mastery][:success].to_i
    bad_casts = @fp.kpi_hash[:mastery][:fail].to_i
    data = table_with_bar(good_casts, bad_casts)

    data[:hash][:title] = 'Mastery: Combo Strikes'
    data[:hash][:desc] = 'Don\'t cast the same spell twice in a row. This table shows when you repeated a spell and did not benefit from mastery.'
    data[:hash][:rows] = @fp.kpi_hash[:mastery][:fail_details].map{|casts| casts.each_with_index.map{|cast, i| {class: (i == 3 ? 'red' : 'green'), value: "(#{@fp.event_time(cast[:timestamp], true)}) #{cast[:ability]}"}}}

    return data
  end

  def self.pressure_point
    return false if @fp.set_bonus(20) < 4
    data = proc_table('Pressure Point', @fp.kpi_hash[:pressure_point_used].to_i, @fp.kpi_hash[:pressure_point_gained].to_i)
    data[:hash][:desc] = "Your T20 4-piece bonus gives your Rising Sun Kick an increased chance to crit for 5 seconds after Fists of Fury. Make sure you always use Rising Sun Kick each time this buff is active."
    return data
  end

  def self.casts
    data = super
    data[:hash][:desc] += " Your haste reduced cooldowns of Rising Sun Kick and Fists of Fury by #{@fp.haste_reduction_percent.round(2)}%. "
    if @fp.set_bonus(19) >= 2
      data[:hash][:desc] += "Your T19 2-set bonus reduced your Rising Sun Kick cooldown by 3 seconds. "
    end
    if @fp.cooldowns_hash[:fof_cdr].to_i > 0
      data[:hash][:desc] += "Your T20 2-piece bonus reduced Fists of Fury's cooldown by a total of #{@fp.cooldowns_hash[:fof_cdr].to_i} seconds."
    end
    return data
  end

  def self.fists_of_fury
    bar_key = 'fists-of-fury-w'
    hash = {
      title: 'Fists of Fury Damage',
      desc: 'The total amount of damage you dealt with Fists of Fury. Damage from your SEF clones and Crosswinds is shown in a lighter color. Make sure to maintain the channel for the full duration.',
      bar_key: 'cd-w',
      val: @fp.cooldowns_hash[:fof_damage].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: number_to_human(@fp.cooldowns_hash[:fof_damage].to_i),
      main_text: "#{number_to_human(@fp.cooldowns_hash[:fof_damage].to_i)} damage",
    }
    if @boss
      hash[:main_bar_text] = number_to_human(@fp.cooldowns_hash[:fof_damage].to_i / @fp.fight_time) + " dps"
      return {hash: hash} 
    end

    cooldowns = @fp.cooldown_parses.where(name: 'Fists of Fury')
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i,
        light_bar_width: 100,
        width: bar_width(item.kpi_hash[:damage_done].to_i, item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i),
        text: number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i)} dmg / #{@fp.fof_hits_s(item.details_hash.values)}",
        dropdown: {
          id: "fof-#{item.id}",
          headers: @fp.fof_headers,
          content: @fp.fof_values(item.details_hash),
        }
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.serenity
    return false if @fp.talent(6) != 'Serenity'
    return cooldown_dps('Serenity', :serenity_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.spinning_crane_kick
    return false if @fp.cooldowns_hash[:sck_damage].to_i == 0
    bar_key = 'spinning-crane-kick-w'
    hash = {
      title: 'Spinning Crane Kick Effectiveness',
      desc: 'The total amount of damage you dealt with Spinning Crane Kick.',
      bar_key: 'cd-w',
      val: @fp.cooldowns_hash[:sck_damage].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: number_to_human(@fp.cooldowns_hash[:sck_damage].to_i),
      main_text: "#{number_to_human(@fp.cooldowns_hash[:sck_damage].to_i)} damage"
    }
    if @boss
      hash[:main_bar_text] = number_to_human(@fp.cooldowns_hash[:sck_damage].to_i / @fp.fight_time) + " dps"
      return {hash: hash} 
    end

    cooldowns = @fp.cooldown_parses.where(name: 'Spinning Crane Kick')
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i,
        light_bar_width: 100,
        width: bar_width(item.kpi_hash[:damage_done].to_i, item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i),
        text: number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i),
        sub_text: "#{item.kpi_hash[:stacks]} enemies marked",
        dropdown: {
          id: "fof-#{item.id}",
          headers: ['Enemy', 'Hits', 'Damage Done', 'Clone Damage'],
          content: item.details_hash.map{|id, hash| [hash[:name], hash[:hits].to_i + hash[:extra_hits].to_i, number_to_human(hash[:damage].to_i), number_to_human(hash[:extra_damage].to_i)]}
        }
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.storm_earth_fire
    return false if @fp.talent(6) == 'Serenity'
    bar_key = 'storm-earth-fire-w'
    hash = {
      title: 'Storm, Earth, and Fire Damage',
      desc: 'The total amount of damage you and your clones dealt while Storm, Earth, and Fire was active.',
      bar_key: 'cd-w',
      val: @fp.cooldowns_hash[:sef_damage].to_i + @fp.cooldowns_hash[:sef_extra_damage].to_i,
      fight_time: @fp.fight_time,
      light_bar_width: 100,
      main_bar_width: bar_width(@fp.cooldowns_hash[:sef_damage].to_i, @fp.cooldowns_hash[:sef_damage].to_i + @fp.cooldowns_hash[:sef_extra_damage].to_i),
      main_bar_text: number_to_human(@fp.cooldowns_hash[:sef_damage].to_i + @fp.cooldowns_hash[:sef_extra_damage].to_i),
      main_text: "#{number_to_human(@fp.cooldowns_hash[:sef_damage].to_i + @fp.cooldowns_hash[:sef_extra_damage].to_i)} damage",
    }
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(name: 'Storm, Earth, and Fire')
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:damage_done].to_i + item.kpi_hash[:pet_damage_done].to_i,
        fight_time: @fp.fight_time,
        light_bar_width: 100,
        width: bar_width(item.kpi_hash[:damage_done].to_i, item.kpi_hash[:damage_done].to_i + item.kpi_hash[:pet_damage_done].to_i),
        text: number_to_human(item.kpi_hash[:damage_done].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:damage_done].to_i)} dmg / #{item.time} sec",
        dropdown: {
          id: "sef-#{item.id}",
          headers: ['Ability', 'Source', 'Hits', 'Damage Done'],
          content: item.details_hash.values.sort{ |a,b| [a[:source].to_s, a[:damage].to_s] <=> [b[:source].to_s, b[:damage].to_s] }.map{|hash| [hash[:name], hash[:source] || @fp.player_name, hash[:hits], number_to_human(hash[:damage])]}
        }
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.strike_of_the_windlord
    data = cooldown_dps('Strike of the Windlord', :stw_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, [:hits, :extra_hits], :damage])
    data[:hash][:desc] += ' Damage from your SEF clones is shown in a lighter color.'
    return data
  end

  def self.touch_of_death
    data = cooldown_dps('Touch of Death', :tod_damage, false, false)
    data[:hash][:desc] += ' Damage gained by Gale Burst is shown in a lighter color.'
    return data
  end

  def self.xuen
    return false if @fp.talent(5) != 'Invoke Xuen, the White Tiger'
    return cooldown_dps('Xuen', :xuen_damage_done, ['Enemy', 'Damage Done'], [:name, :damage])
  end

end