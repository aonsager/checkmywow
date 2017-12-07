class DisplaySection::Paladin::RetributionDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps,
        judgment_holypower,
        debuff_graphs('Judgment', :judgment, {no_score: true}),
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_gain('Holy Power'),
        resource_damage('Holy Power'),
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        crusade,
        crusade_holypower,
        avenging_wrath,
      ]
    end
  end
  
  def self.judgment_holypower
    percent = 100 * @fp.kpi_hash[:hp_with_judgment].to_i / (@fp.kpi_hash[:hp_with_judgment].to_i + @fp.kpi_hash[:hp_without_judgment].to_i) rescue 0
    hash = {
      title: 'Spend Holy Power while Judgment is active',
      desc: 'You should try to spend your Holy Power while Judgment is active on the enemy you are attacking. 100% is probably unrealistic, but try to maximize this efficiency.',
      label: percent >= 90 ? 'good' : percent >= 80 ? 'ok' : 'bad',
      white_bar: true,
      main_bar_width: bar_width(@fp.kpi_hash[:hp_with_judgment].to_i, @fp.kpi_hash[:hp_with_judgment].to_i + @fp.kpi_hash[:hp_without_judgment].to_i),
      main_bar_text: "#{@fp.kpi_hash[:hp_with_judgment].to_i} / #{@fp.kpi_hash[:hp_with_judgment].to_i + @fp.kpi_hash[:hp_without_judgment].to_i}",
      main_text: "#{percent}% with Judgment",
    }
    return {hash: hash} if @boss

    bar_key = 'hp_casts-w'
    hash[:sub_bars] = @fp.kpi_hash[:hp_judgment_casts].nil? ? nil : @fp.kpi_hash[:hp_judgment_casts].values.sort{|a, b| b[:active].to_i + b[:inactive].to_i <=> a[:active].to_i + a[:inactive].to_i}.map{|item| 
      {
        label: item[:name],
        white_bar: true,
        bar_key: bar_key,
        val: item[:active].to_i + item[:inactive].to_i,
        width: bar_width(item[:active].to_i, item[:active].to_i + item[:inactive].to_i),
        text: "#{item[:active].to_i} / #{item[:active].to_i + item[:inactive].to_i}",
        sub_text: "#{item[:active].to_i} / #{item[:active].to_i + item[:inactive].to_i}",
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.casts
    data = super
    data[:hash][:desc] += " Your haste reduced cooldowns of your key abilities by #{@fp.haste_reduction_percent.round(2)}%. "
    return data
  end

  def self.crusade
    return false if @fp.talent(6) != 'Crusade'
    return cooldown_dps('Crusade', :crusade_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.crusade_holypower
    hash = {
      title: 'Holy Power Spent During Crusade',
      desc: 'The total amount of Holy Power you spent while Crusade was active. You should pool Holy Power to spend while Crusade is active, to maximize the haste buff',
      val: @fp.cooldowns_hash[:crusade_avghp].to_i,
      main_bar_text: "#{@fp.cooldowns_hash[:crusade_avghp].to_i}",
      main_text: "#{@fp.cooldowns_hash[:crusade_avghp].to_i} Holy Power / cast"
    }
    return {hash: hash} if @boss

    cooldowns = @fp.cooldown_parses.where(name: 'Crusade')
    bar_key = 'crusadehp-w'
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:hp_spent].to_i,
        text: "#{item.kpi_hash[:hp_spent].to_i}",
        sub_text: "#{item.kpi_hash[:hp_spent].to_i} Holy Power",
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.avenging_wrath
    return false if @fp.talent(6) == 'Crusade'
    return cooldown_dps('Avenging Wrath', :avenging_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

end