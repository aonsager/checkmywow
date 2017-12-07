class DisplaySection::Warrior::ArmsDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps,
        debuff_graphs('Colossus Smash', :colossus_smash),
        proc_table('Shattered Defenses', @fp.kpi_hash[:shattered_defenses_used].to_i, @fp.kpi_hash[:shattered_defenses_procs].to_i, ['Timestamp', 'Details'], @fp.kpi_hash[:shattered_defenses_fails]),
        rend,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_gain('Rage'),
        execute_rage,
        execute_mortal_strike,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        execute_range,
        cooldown_dps('Battle Cry', :battle_cry_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        avatar,
        bladestorm,
        ravager,
      ]
    end
  end
  
  def self.rend
    return false if @fp.talent(2) != 'Rend'
    return debuff_graphs('Rend', :rend, {no_score: true})
  end

  def self.execute_rage
    data = resource_damage('Rage')
    data[:hash][:title] = 'Rage Usage during Execute Range'
    data[:hash][:desc] = "The amount of damage per Rage you did with each ability while the enemy was in execute range (<20% HP), ordered by the total amount of Rage spent. Execute and Mortal Strike should be at the top of this list"
    return data
  end

  def self.execute_mortal_strike
    data = proc_table('', @fp.resources_hash[:good_execute_mortal_strike].to_i, @fp.resources_hash[:good_execute_mortal_strike].to_i + @fp.resources_hash[:bad_execute_mortal_strike].to_i, ['Timestamp', 'Details'], @fp.resources_hash[:bad_execute_mortal_strikes])
    data[:hash][:title] = 'Mortal Strike Usage during Execute Range'
    data[:hash][:desc] = 'When your enemy is in execute range (<20% HP) you should use Mortal Strike when Shattered Defenses is active with 2 stacks of Executioner\'s Precision on your enemy.'
    return data
  end

  def self.execute_range
    bar_key = 'execute-range-w'
    hash = {
      title: 'Damage Done while in Execute Range',
      desc: 'The total amount of damage you dealt to your enemies while they were in Execute range (<20% HP). This is when you have the highest damage output potential, so do your best to maximize your damage.',
      bar_key: 'cd-w',
      val: @fp.cooldowns_hash[:execute_range_damage].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: number_to_human(@fp.cooldowns_hash[:execute_range_damage].to_i),
      main_text: "#{number_to_human(100 * @fp.cooldowns_hash[:execute_range_damage].to_i / @fp.kpi_hash[:player_damage_done])}% total damage",
    }
    return {hash: hash} if @boss

    debuffs = @fp.debuff_parses.where(name: 'Execute Range')
    hash[:sub_bars] = debuffs.nil? ? nil : debuffs.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:damage_done].to_i,
        text: number_to_human(item.kpi_hash[:damage_done].to_i),
        sub_text: item.target_name,
        dropdown: {
          id: "execute-range-#{item.id}",
          headers: ['Ability', 'Damage Done', 'Hits'],
          content: item.details_hash.values.sort{|a, b| b[:damage].to_i <=> a[:damage].to_i}.map{|hash| [hash[:name], number_to_human(hash[:damage].to_i), hash[:hits].to_i]}
        }
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.avatar
    return false if @fp.talent(2) != 'Avatar'
    return cooldown_dps('Avatar', :avatar_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.bladestorm
    return false if @fp.talent(6) == 'Ravager'
    return cooldown_dps('Bladestorm', :bladestorm_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.ravager
    return false if @fp.talent(6) != 'Ravager'
    return cooldown_dps('Ravager', :ravager_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

end