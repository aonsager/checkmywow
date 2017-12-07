class DisplaySection::Hunter::BeastmasteryDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        # proc_table('Wild Call', @fp.kpi_hash[:wildcall_procs].to_i, @fp.kpi_hash[:wildcall_procs].to_i + @fp.kpi_hash[:wildcall_wasted].to_i, ['Timestamp', 'Event'], @fp.kpi_hash[:wildcall_waste_details]),
        titans_thunder,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_cap('Focus'),
        resource_gain('Focus'),
        resource_damage('Focus'),
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        killer_cobra,
        cooldown_dps('Bestial Wrath', :bestial_wrath_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        cooldown_dps('Aspect of the Wild', :aspect_of_the_wild_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        cooldown_dps('Titan\'s Thunder', :titans_thunder_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        murder_of_crows,
        barrage,
        stampede,
      ]
    end
  end

  def self.titans_thunder
    return false if @fp.talent(1) == 'Dire Frenzy'
    data = table_with_bar(@fp.kpi_hash[:thunder_with_dire].to_i, @fp.kpi_hash[:thunder_without_dire].to_i)
    data[:hash][:title] = 'Titan\'s Thunder Usage'
    data[:hash][:desc] = 'The number of times you cast Titan\'s Thunder while Dire Beast was active. Try to line these up as much as possible, to maximize damage.'
    if !@fp.kpi_hash[:thunder_fail_details].nil? && @fp.kpi_hash[:thunder_fail_details].count > 0
      data[:hash][:labels] = ['Time', 'Cast']
      data[:hash][:rows] = @fp.kpi_hash[:thunder_fail_details].nil? ? nil : @fp.kpi_hash[:thunder_fail_details].map{|row| [{value: @fp.event_time(row[:timestamp], true)}, {value: row[:msg]}]}
    end
    return data
  end
  
  def self.casts
    data = super
    data[:hash][:desc] = "These are your key spells that should be cast as often as possible. Make sure you are casting them on cooldown. Your cast score is determined by a weighted average, with more emphasis placed on abilities with longer cooldown times. Your haste reduced cooldowns of Dire Beast/Dire Frenzy, and Chimaera Shot by #{@fp.haste_reduction_percent.round(2)}%. Dire Beast\'s cooldown reduction provided #{@fp.kpi_hash[:direbeast_reduction].to_i / 90} extra casts of Bestial Wrath."
    return data
  end

  def self.killer_cobra
    return false if @fp.talent(6) != 'Killer Cobra'
    hash = {
      title: 'Killer Cobra Effectiveness',
      desc: 'This section shows how many times you cast Cobra Shot -> Kill Command during Bestial Wrath.',
      white_bar: true,
      main_bar_width: bar_width(@fp.cooldowns_hash[:bestial_kill].to_i, @fp.cooldowns_hash[:bestial_cobra].to_i),
      main_bar_text: "#{@fp.cooldowns_hash[:bestial_kill].to_i} / #{@fp.cooldowns_hash[:bestial_cobra].to_i}",
      main_text: "#{@fp.cooldowns_hash[:bestial_kill].to_i} Kill Commands, #{@fp.cooldowns_hash[:bestial_cobra].to_i} Cobra Shots",
    } 
    return {hash: hash} if @boss

    hash[:sub_bars] = []
    cooldowns = @fp.cooldown_parses.where(name: 'Bestial Wrath')
    bar_key = 'cobra-w'
    hash[:sub_bars] = cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:killercobra].to_i,
        white_bar: true,
        width: bar_width(item.kpi_hash[:killcommand].to_i, item.kpi_hash[:killercobra].to_i),
        text: "#{item.kpi_hash[:killcommand].to_i} / #{item.kpi_hash[:killercobra].to_i}",
        sub_text: "#{item.kpi_hash[:killcommand].to_i} KC, #{item.kpi_hash[:killercobra].to_i} CS",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.murder_of_crows
    return false if @fp.talent(5) != 'A Murder of Crows'
    return cooldown_dps('A Murder of Crows', :a_murder_of_crows_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.barrage
    return false if @fp.talent(5) != 'Barrage'
    return cooldown_dps('Barrage', :barrage_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.stampede
    return false if @fp.talent(6) != 'Stampede'
    return cooldown_dps('Stampede', :stampede_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

end