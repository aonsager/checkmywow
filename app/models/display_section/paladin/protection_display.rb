class DisplaySection::Paladin::ProtectionDisplay < DisplaySection

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
        light_of_the_protector,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        cpm,
        shield_uptime,
        buff_stacks_graph('Consecration', @fp.resources_hash[:consecration_uptime].to_i),
        blessed_hammer,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        eye_of_tyr,
        ardent_defender,
        guardian,
        cooldown_dps('Avenging Wrath', :avenging_wrath_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        healing_buff_cooldown('Avenging Wrath', 'avenging_wrath'),
      ]
    when 'hp'
      return [
        health_graph,
      ]
    end
  end

  def self.light_of_the_protector
    average_value = @fp.kpi_hash[:protector_values].inject{ |sum, el| sum + el } / @fp.kpi_hash[:protector_values].size rescue 0
    hash = {
      title: 'Light of the Protector Healing',
      desc: 'This section shows how much HP you healed with each cast of Light of the Protector, as a percent of total HP. It\'s not necessarily bad to have low values if you aren\'t taking much damage, but consider that correctly timing your heals can improve your survivability',
      val: average_value,
      white_bar: true,
      main_bar_width: bar_width(average_value, 50),
      main_bar_text: "#{average_value}%",
      main_text: "#{average_value}% average",
    }
    return {hash: hash} if @boss

    hash[:sub_bars] = @fp.kpi_hash[:protector_casts].nil? ? nil : @fp.kpi_hash[:protector_casts].map{|key, count| 
      {
        label: "< #{key + 10}%", 
        bar_key: 'protector-w',
        val: count,
        text: count,
        sub_text: "#{count} casts",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: 'protector-w'}
  end
  
  def self.casts
    data = super
    data[:hash][:desc] += " Your haste reduced cooldowns of #{@fp.talent(0) == 'Blessed Hammer' ? 'Blessed Hammer' : 'Hammer of the Righteous'} and Judgment by #{@fp.haste_reduction_percent.round(2)}%."
    return data
  end

  def self.cpm
    hash = {
      title: 'Casts per Minute',
      desc: 'There isn\'t a set value you should be aiming for, but you generally want this value to be high.',
      val: @fp.resources_hash[:cpm],
      main_bar_width: 100,
      main_bar_text: @fp.resources_hash[:cpm],
      main_text: "#{@fp.resources_hash[:cpm]} casts/minute",
    }
    return {hash: hash} if @boss
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.shield_uptime
    uptime = @fp.resources_hash[:shield_uptime].to_i
    uptime_percent = @fp.resources_hash[:shield_uptime].to_i / (10 * @fp.fight_time)
    score = 100 - (70 - uptime_percent)
    data = buff_stacks_graph('Shield of the Righteous', uptime, score)
    data[:hash][:desc] += ' You should generally aim for around 70% uptime.'
    return data
  end

  def self.blessed_hammer
    data = debuff_graphs('Blessed Hammer', :blessed_hammer)
    data[:hash][:label] = nil
    data[:hash][:desc] = "The percentage of time Blessed Hammer was active on targets you were attacking. A red area means that you were attacking an enemy without Blessed Hammer active. Aim for close to 100% uptime on all targets."
    return data
  end

  def self.eye_of_tyr
    data = cooldown_damage_reduction('Eye of Tyr', :eye_of_tyr_reduced, ['Enemy', 'Ability', 'Casts', 'Reduced damage'], [:source, :name, :casts, :amount])
    data[:desc] = 'The total amount of damage mitigated through Eye of Tyr\'s debuff. Each cast of Eye of Tyr records all damage taken while it is up, and calculates the total mitigation (25%).'
    return data
  end

  def self.ardent_defender
    data = cooldown_damage_reduction('Ardent Defender', :ardent_defender_reduced, ['Enemy', 'Ability', 'Casts', 'Reduced damage'], [:source, :name, :casts, :amount])
    data[:desc] = 'The total amount of damage mitigated through Ardent Defender. Each cast of Ardent Defender records all damage taken while it is up, and calculates the total mitigation (20%).'
    return data
  end

  def self.guardian
    data = cooldown_damage_reduction('Guardian of Ancient Kings', :guardian_reduced, ['Enemy', 'Ability', 'Casts', 'Reduced damage'], [:source, :name, :casts, :amount])
    data[:desc] = 'The total amount of damage mitigated through Guardian of Ancient Kings. Each cast of Guardian of Ancient Kings records all damage taken while it is up, and calculates the total mitigation (50%).'
    return data
  end

end