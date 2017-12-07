class DisplaySection::Priest::ShadowDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        debuff_graphs('Shadow Word: Pain', :pain),
        debuff_graphs('Vampiric Touch', :vampiric),
        voidray,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        insanity_gain,
        voidform_insanity,
        abc,
      ]
    when 'cooldowns'
      return [
        cooldown_dps('Voidform', :voidform_damage, ['Spell', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        cooldown_dps('Shadow Word: Death', :swd_damage),
        power_infusion_damage,
      ]
    end
  end

  def self.voidray
    uptime = @fp.kpi_hash[:voidray_uptime].to_i
    return false if uptime == 0
    return buff_stacks_graph('Void Ray', uptime, nil)
  end
  
  def self.casts
    data = super
    data[:hash][:desc] += " This is a very conservative estimate, since increased haste will greatly reduce cooldowns as Voidform continues. For Void Bolt and Void Torrent, it only consideres the total time you spent in Voidform (#{(@fp.resources_hash[:voidform_uptime].to_i / 1000.0).round(2)} seconds)"
    return data
  end

  def self.insanity_gain
    data = resource_gain('Insanity')
    data[:hash][:title] = "Insanity Gained Outside of Voidform"
    data[:hash][:desc] = "Focus on generating Insanity efficiently while outside of Voidform, to maximize Voidform\'s uptime."
    return data
  end

  def self.voidform_insanity
    hash = {
      title: 'Voidform Uptime and Insanity Gained',
      desc: "Generate as much Insanity as possible while in Voidform, to maximize Voidform's uptime. It's ok to waste Insanity at the beginning of Voidform; wasted amount is shown here just to give an idea of the total amount generated.",
      white_bar: true,
      main_bar_width: bar_width(@fp.resources_hash[:voidform_uptime].to_i, (@fp.ended_at - @fp.started_at)),
      main_bar_text: "#{100 * @fp.resources_hash[:voidform_uptime].to_i / (@fp.ended_at - @fp.started_at)}% of fight",
      main_text: "#{@fp.resources_hash[:voidform_uptime].to_i / 1000} sec uptime",
    }
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(name: 'Voidform')
    bar_key = 'voidform-w'
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.time,
        white_bar: true,
        width: bar_width(item.kpi_hash[:insanity_gained].to_i, item.kpi_hash[:insanity_gained].to_i + item.kpi_hash[:insanity_wasted].to_i),
        text: "#{item.kpi_hash[:insanity_gained].to_i}/#{item.kpi_hash[:insanity_gained].to_i + item.kpi_hash[:insanity_wasted].to_i} Insanity gained",
        sub_text: "#{item.time} sec uptime",
        dropdown: {
          id: "void-#{item.id}",
          headers: ['Spell', 'Casts', 'Insanity Gained', 'Insanity Wasted'],
          content: item.kpi_hash[:insanity_abilities].values.sort{|a, b| b[:gain] <=> a[:gain]}.map{|hash| [hash[:name], hash[:casts].to_i, hash[:gain].to_i, hash[:waste].to_i]}
        }
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.power_infusion_damage
    return false if @fp.talent(5) != 'Power Infusion'
    return cooldown_dps('Power Infusion', :power_damage, ['Spell', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

end