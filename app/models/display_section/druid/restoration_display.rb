class DisplaySection::Druid::RestorationDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        healing,
        external_buff_graphs('Lifebloom', :lifebloom, {target_uptime: 85}),
        external_buff_graphs('Rejuvenation', :rejuvenation),
        mastery,
        mastery_stacks,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        healing_per_mana,
        soul_of_the_forest,
        regrowth,
        abc,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        healing_cooldown('Tranquility', 'tranquility'),
        healing_cooldown('Wild Growth', 'wildgrowth'),
        ghanir,
        incarnation,
      ]
    when 'raid_hp'
      return [
        raid_health_graph,
      ]
    end
  end

  def self.mastery
    hash = {
      title: 'Mastery: Harmony Healing Increase',
      desc: "This section shows the total increased healing from Mastery: Harmony over the course of the fight. Overhealing is shown as the white part of the bar. The sub-bars show how much healing was gained from heals based on how many stacks were active. Mastery will have higher value as a stat if you can consistently keep high stacks on your raid members as you heal them.",
      white_bar: true,
      main_bar_width: bar_width(@fp.kpi_hash[:mastery_healing_increase].to_i, @fp.kpi_hash[:mastery_healing_increase].to_i + @fp.kpi_hash[:mastery_overhealing_increase].to_i),
      main_bar_text: "#{number_to_human(@fp.kpi_hash[:mastery_healing_increase].to_i)} heal, #{number_to_human(@fp.kpi_hash[:mastery_overhealing_increase].to_i)} overheal",
      main_text: "#{100 * @fp.kpi_hash[:mastery_healing_increase].to_i / @fp.kpi_hash[:healing_done].to_i rescue 0}% increase"
    }
    return {hash: hash} if @boss

    bar_key = 'mastery_healing'
    hash[:sub_bars] = @fp.kpi_hash[:mastery_stacks].nil? ? nil : @fp.kpi_hash[:mastery_stacks].map{|stacks, item|
      {
        label: "#{stacks} stacks",
        bar_key: bar_key,
        val: item[:healing_increase].to_i + item[:overhealing_increase].to_i,
        white_bar: true,
        width: bar_width(item[:healing_increase].to_i, item[:healing_increase].to_i + item[:overhealing_increase].to_i),
        text: number_to_human(item[:healing_increase].to_i),
        sub_text: "#{number_to_human(item[:healing_increase].to_i)} healing (#{number_to_human(item[:overhealing_increase].to_i)} overhealing)",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end
  
  def self.mastery_stacks
    hash = {
      title: 'Mastery: Harmony Uptime',
      desc: "Tracks the number of HOTs on your targets over time, to see how they benefited from Mastery: Harmony. A dark green color shows when you had 3 or more HOTs active at the same time. Try to maximize uptime on tanks and other primary targets.",
      white_bar: true,
      dropdown: {id: 'mastery_stacks'},
      main_bar_width: @fp.buff_upratio(:mastery),
      main_bar_text: @fp.buff_upratio_s(:mastery),
      main_text: @fp.buff_upratio_s(:mastery)
    }
    return {hash: hash} if @boss

    external_buffs = @fp.external_buff_parses.where(name: 'Mastery: Harmony')
    hash[:sub_bar_type] = 'debuff'
    hash[:sub_bars] = external_buffs.nil? ? nil : external_buffs.sort{|a, b| b.kpi_hash[:uptime].to_i <=> a.kpi_hash[:uptime].to_i}.map{|item| 
      {
        debuff: item,
        label: item.target_name,
        id: "debuff-#{item.id}-#{item.target_id}",
        sub_text: item.upratio_s,
        stacks: 3,
        stack_colors: {1 => '#c5ffd4', 2=> '#5fff87', 3 => '#00C532'},
        hide_down: true,
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.soul_of_the_forest
    return false if @fp.talent(4) != 'Soul of the Forest'
    data = proc_usage('Soul of the Forest', @fp.resources_hash[:soul_uses].to_i, @fp.resources_hash[:soul_procs].to_i, @fp.resources_hash[:soul_abilities])
    data[:hash][:desc] = 'Take advantage of your Soul of the Forest procs, by casting Swiftmend followed by Wild Growth.'
    return data
  end

  def self.regrowth
    data = proc_table('Regrowth', @fp.resources_hash[:good_regrowths].to_i, @fp.resources_hash[:good_regrowths].to_i + @fp.resources_hash[:bad_regrowths].to_i, ['Timestamp', 'Details'], @fp.resources_hash[:regrowth_fails])
    data[:hash][:desc] = 'You should only cast Regrowth when you have a Clearcasting proc. Also be sure that you spend your Clearcasting procs before they are overwritten'
    return data
  end

  def self.ghanir
    data = healing_buff_cooldown('Essence of G\'Hanir', 'ghanir')
    data[:hash][:desc] += ' This accounts for all extra ticks gained from your HoTs. Try to use this spell when you have many active HoTs on your raid members.'
    return data
  end

  def self.incarnation
    return false if @fp.talent(4) != 'Incarnation: Tree of Life'
    return healing_buff_cooldown('Incarnation: Tree of Life', 'incarnation')
  end

  

end