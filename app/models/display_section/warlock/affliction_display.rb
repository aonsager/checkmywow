class DisplaySection::Warlock::AfflictionDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        debuff_graphs('Agony', :agony),
        debuff_graphs('Corruption', :corruption, {single_target: true}),
        unstable_uptimes,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_gain('Soulshard'),
        abc,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        soul_harvest,
        tormented_souls,
        unstable_cooldowns,
        unstable_drain_soul,
      ]
    end
  end

  def self.unstable_uptimes
    data = debuff_graphs('Unstable Affliction', :unstable_affliction, {target_stacks: 2})
    data[:hash][:label] = nil
    return data
  end

  def self.soul_harvest
    return false if @fp.talent(3) != 'Soul Harvest'
    return cooldown_dps('Soul Harvest', :soul_harvest_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.tormented_souls
    return cooldown_dps('Tormented Souls', :tormented_souls_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.unstable_cooldowns
    return cooldown_dps('Unstable Affliction', :unstable_affliction_damage, ['Enemy', 'Ticks', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.unstable_drain_soul
    return false if @fp.talent(0) != 'Malefic Grasp'
    bar_key = 'unstable-drain-soul-w'
    hash = {
      title: 'Drain Soul Uptime During Unstable Affliction',
      desc: 'When choosing Malefic Grasp as a talent, you should aim to be channeling Drain Soul as much as possible after placing 2 stacks of Unstable Affliction on your target. This section should your Drain Soul uptime during times when Unstable Affliction was active.',
      white_bar: true,
      main_bar_width: bar_width(@fp.cooldowns_hash[:drain_soul_during_ua].to_i, @fp.cooldowns_hash[:unstable_affliction_active_time].to_i),
      main_bar_text: (100 * @fp.cooldowns_hash[:drain_soul_during_ua].to_i / @fp.cooldowns_hash[:unstable_affliction_active_time].to_i rescue 0).to_s + "%",
      main_text: "#{@fp.cooldowns_hash[:drain_soul_during_ua].to_i / 1000}/#{@fp.cooldowns_hash[:unstable_affliction_active_time].to_i / 1000} seconds",
    }
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(name: 'Unstable Affliction')
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:active_time].to_i,
        white_bar: true,
        width: bar_width(item.kpi_hash[:drain_soul_uptime].to_i, item.kpi_hash[:active_time].to_i),
        text: (100 * item.kpi_hash[:drain_soul_uptime].to_i / item.kpi_hash[:active_time].to_i rescue 0).to_s + "%",
        sub_text: "#{item.kpi_hash[:drain_soul_uptime].to_i / 1000}/#{item.kpi_hash[:active_time].to_i / 1000} seconds",
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

end