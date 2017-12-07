class DisplaySection::Monk::BrewmasterDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps,
        damage_taken,
        self_healing,
        external_healing,
        brewstache,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_cap('Energy'),
        blackout_combo,
        ironskin_brew,
        purifying_brew,
        stagger,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        exploding_keg,
        dampen_harm,
        zen_meditation,
        fortifying_brew,
      ]
    when 'hp'
      return [
        health_graph,
      ]
    end
  end
  
  def self.casts
    data = super
    data[:hash][:desc] += " Your haste reduced cooldowns of Keg Smash and your brews by #{@fp.haste_reduction_percent.round(2)}%, and you reduced the cooldowns of your brews by an additional #{@fp.brew_reduction} seconds."
    return data
  end

  def self.brewstache
    uptime = @fp.resources_hash[:brewstache_uptime].to_i
    return buff_stacks_graph('Brew-Stache', uptime, nil)
  end

  def self.blackout_combo
    return false if @fp.talent(6) != 'Blackout Combo'
    data = proc_usage('Blackout Combo', @fp.resources_hash[:boc_used].to_i, @fp.resources_hash[:boc_gained].to_i)
    data[:hash][:sub_bars] = @fp.resources_hash[:boc_abilities].values.sort{|a, b| b[:casts].to_i <=> a[:casts].to_i}.map{|item| 
      {
        label: item[:name],
        bar_key: 'blackout-combo-w',
        val: item[:casts].to_i,
        text: "#{item[:casts].to_i}",
        sub_text: "#{item[:casts].to_i}/#{@fp.casts_hash[item[:name]].size rescue 0} casts",
      }
    } 
    data[:resize] = 'blackout-combo-w'
    return data
  end

  def self.ironskin_brew
    hash = {
      title: 'Ironskin Brew Effectiveness',
      desc: 'The total amount of extra damage converted to Stagger while Ironskin Brew was active (40%). Use Ironskin Brew during periods of high damage for a smoother damage intake.',
      val: @fp.resources_hash[:isb_stagger].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: number_to_human(@fp.resources_hash[:isb_stagger].to_i),
      main_text: "#{number_to_human(@fp.resources_hash[:isb_stagger].to_i)} staggered",
    }
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(name: 'Ironskin Brew')
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: 'ironskin-brew-w',
        val: item.kpi_hash[:absorbed_amount].to_i,
        text: number_to_human(item.kpi_hash[:absorbed_amount].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:absorbed_amount].to_i)} dmg",
        dropdown: {
          id: "isb-#{item.id}",
          headers: ['Enemy', 'Ability', 'Casts', 'Stagger'],
          content: item.details_hash.values.sort{|a,b| b[:amount] <=> a[:amount] }.map{|hash| [hash[:source], hash[:name], hash[:casts], hash[:amount]]}
        }
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: 'ironskin-brew-w'}
  end

  def self.purifying_brew
    hash = {
      title: 'Purifying Brew Effectiveness',
      desc: 'The total amount of Stagger removed by Purifying Brew. Try to use this when your stagger is highest, or just after Ironskin Brew wears off.',
      val: @fp.resources_hash[:stagger_purified].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: number_to_human(@fp.resources_hash[:stagger_purified].to_i),
      main_text: "#{number_to_human(@fp.resources_hash[:stagger_purified].to_i)} damage",
    }
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(name: 'Purifying Brew')
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: 'purifying-brew-w',
        val: item.kpi_hash[:purified_amount].to_i,
        text: number_to_human(item.kpi_hash[:purified_amount].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:purified_amount].to_i)} dmg",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: 'purifying-brew-w'}
  end

  def self.stagger
    return false if @boss
    hash = {
      title: 'Stagger',
      desc: 'Shows your stagger pool over time, including periods when it was increased by Ironskin Brew, and when it was cleared by Purifying Brew. Use Ironskin Brew (blue) to create high peaks, and Purifying Brew (purple) at the top of those peaks.',
      graph_type: 'stagger',
    }
    return {partial: 'fight_parses/shared/class_graph', hash: hash}
  end

  def self.exploding_keg
    data = cooldown_damage_reduction('Exploding Keg', :keg_avoided, ['Enemy', 'Missed Count', 'Avg. dmg'], [:source, :dodged, :avg])
    data[:desc] = 'The total amount of damage mitigated through Exploding Keg\'s debuff. The effectiveness of each invididual Exploding Keg cast is calculated by recording each melee attack that missed, and summing the damage it would have done had it hit you, based on average damage taken from that enemy over the course of the fight.'
    return data
  end

  def self.dampen_harm
    return false if @fp.talent(4) != 'Dampen Harm'
    data = cooldown_damage_reduction('Dampen Harm', :dh_reduced, ['Enemy', 'Ability', 'Reduced damage'], [:source, :name, :amount])
    data[:desc] = 'The total amount of damage mitigated through Dampen Harm / fight time. Each cast of Dampen Harm has its 3 highest hitting attacks recorded, and calculates the total damage mitigation (50% if the attack did >15% of your total health). Because the mitigation happens before any damage is recorded, it\'s difficult to know for sure whether an attack that did between 7.5-15% of your total health was actually mitigated or not.'
    return data
  end

  def self.zen_meditation
    data = cooldown_damage_reduction('Zen Meditation', :zm_reduced, ['Enemy', 'Ability', 'Casts', 'Reduced damage'], [:source, :name, :casts, :amount])
    data[:desc] = 'The total amount of damage mitigated through Zen Meditation / fight time. Each cast of Zen Meditation records all damage taken while it is up, and calculates the total mitigation (90%).'
    return data
  end

  def self.fortifying_brew
    data = cooldown_damage_reduction('Fortifying Brew', :fb_reduced, ['Enemy', 'Ability', 'Casts', 'Reduced damage'], [:source, :name, :casts, :amount])
    data[:desc] = 'The total amount of damage mitigated through Fortifying Brew / fight time. Each cast of Fortifying Brew records all damage taken while it is up, and calculates the total mitigation (20%). Increased Stagger is not taken into effect here, so its total effectiveness may be understated.'
    return data
  end

end