class DisplaySection::Demonhunter::HavocDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps,
        momentum_fury_gain,
        momentum_fury_spend,
        momentum_casts,
        momentum_overlap,
        momentum_uptime,
        eye_beam_multi,
        blade_dance_multi,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        resource_gain('Fury'),
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        fury_of_the_illidari,
        eye_beam_damage,
        metamorphosis_damage,
        chaos_blades_damage,
        fel_barrage_damage,
      ]
    end
  end

  def self.momentum_fury_gain
    return false if @fp.talent(4) != 'Momentum' || @fp.talent(1) == 'Demon Blades'
    good_casts = @fp.kpi_hash[:fury_good_gain].to_i
    bad_casts = @fp.kpi_hash[:fury_bad_gain].to_i
    data = table_with_bar(good_casts, bad_casts)
    return false if !data

    data[:hash][:title] = 'Momentum - Fury Generation'
    data[:hash][:desc] = 'You should only generate Fury if Momentum is not active or if you have less than 40 Fury left. This section shows how many times you generated Fury with Demon\'s Bite, while satisfying those conditions.'
    data[:hash][:dropdown] = {id: 'fury-gen'}
    data[:hash][:labels] = ['Time', 'Cast']
    data[:hash][:rows] = @fp.kpi_hash[:fury_bad_gain_casts].nil? ? nil : @fp.kpi_hash[:fury_bad_gain_casts].map{|row| [{value: @fp.event_time(row[:timestamp], true)}, {value: row[:msg]}]}

    return data
  end

  def self.momentum_fury_spend
    return false if @fp.talent(4) != 'Momentum' || @fp.talent(1) == 'Demon Blades'
    good_casts = @fp.kpi_hash[:fury_good_spend].to_i
    bad_casts = @fp.kpi_hash[:fury_bad_spend].to_i
    data = table_with_bar(good_casts, bad_casts)
    return false if !data

    data[:hash][:title] = 'Momentum - Fury Spending'
    data[:hash][:desc] = 'If you haven\'t taken Demon Blades as a talent, you should try to only spend Fury if Momentum is active or if you are less than 30 Fury from capping. This section shows how many times you spend Fury with Chaos Strike, while satisfying those conditions.'
    data[:hash][:dropdown] = {id: 'fury-spend'}
    data[:hash][:labels] = ['Time', 'Cast']
    data[:hash][:rows] = @fp.kpi_hash[:fury_bad_spend_casts].nil? ? nil : @fp.kpi_hash[:fury_bad_spend_casts].map{|row| [{value: @fp.event_time(row[:timestamp], true)}, {value: row[:msg]}]}

    return data
  end

  def self.momentum_casts
    return false if @fp.talent(4) != 'Momentum'
    data = success_bars(@fp.kpi_hash[:momentum_score].to_i)
    return false if !data
    data[:hash][:title] = 'Casts During Momentum'
    data[:hash][:desc] = 'Cast your important spells while Momentum is active, to take advantage of the increased damage. This shows the percentage or your total casts (or ticks) that benefited from Momentum\'s damage buff.'
    return data if @boss
    

    data[:hash][:sub_bars] = @fp.momentum_cast_bars.nil? ? nil : @fp.momentum_cast_bars.map{|item| 
      {
        label: item[:name],
        white_bar: true,
        width: bar_width(item[:good].to_i, item[:total].to_i),
        text: "#{item[:good].to_i}/#{item[:total].to_i}",
        sub_text: "#{item[:good].to_i}/#{item[:total].to_i}",
      }
    }
    return data
  end

  def self.momentum_overlap
    return false if @fp.talent(4) != 'Momentum'
    good_casts = @fp.kpi_hash[:momentum_count].to_i
    bad_casts = @fp.kpi_hash[:early_momentum_count].to_i
    data = table_with_bar(good_casts, bad_casts)
    return false if !data

    data[:hash][:title] = 'Momentum Gained Without Overlapping'
    data[:hash][:desc] = 'You should never refresh Momentum by casting Vengeful Retreat while it is still active, because this will reduce your total uptime. Note that refreshing Momentum early with Fel Rush can be ok, as long as you are hitting multiple targets.'
    data[:hash][:dropdown] = {id: 'momentum-overlap'}
    data[:hash][:labels] = ['Time', 'Details']
    data[:hash][:rows] = @fp.kpi_hash[:early_momentum_casts].nil? ? nil : @fp.kpi_hash[:early_momentum_casts].map{|row| [{value: @fp.event_time(row[:timestamp], true), class: row[:class]}, {value: row[:msg]}]}
    return data
  end

  def self.momentum_uptime
    return false if @fp.talent(4) != 'Momentum'
    uptime = @fp.resources_hash[:momentum_uptime].to_i
    uptime_percent = @fp.resources_hash[:momentum_uptime].to_i / (10 * @fp.fight_time)
    score = 100 - (@fp.max_momentum - uptime_percent)
    data = buff_stacks_graph('Momentum', uptime, score)
    return false if !data

    data[:hash][:desc] = "The duration that you had Momentum active, from casting of Fel Rush and Vengeful Retreat. Because you #{@fp.talent(1) == 'Prepared' ? 'chose' : 'did not choose'} Prepared as a talent, you can achieve a maximum of #{@fp.max_momentum}% uptime#{ @fp.artifact('Demon Speed') ? ', by also generating Fel Rush charges from Blur' : ''}. High AOE fights will lead to a lower uptime since you should be prioritizing Fel Rush damage over buff uptime." unless data
    return data
  end

  def self.eye_beam_multi
    good_casts = @fp.kpi_hash[:eyebeam_multiple].to_i
    bad_casts = @fp.kpi_hash[:eyebeam_ticks].to_i - @fp.kpi_hash[:eyebeam_multiple].to_i
    data = table_with_bar(good_casts, bad_casts)
    return false if !data

    data[:hash][:title] = 'Eye Beam Targets'
    data[:hash][:desc] = 'Only cast Eye Beam if you will hit multiple targets. This section show how many of your Eye Beam ticks hit multiple targets.'
    return data
  end

  def self.blade_dance_multi
    return false if @fp.talent(2) == 'First Blood' || @fp.kpi_hash[:blade_dance].to_i == 0
    good_casts = @fp.kpi_hash[:blade_dance].to_i - @fp.kpi_hash[:bad_blade_dance].to_i
    bad_casts = @fp.kpi_hash[:bad_blade_dance].to_i
    data = table_with_bar(good_casts, bad_casts)
    return false if !data

    data[:hash][:title] = 'Blade Dance Targets'
    data[:hash][:desc] = 'Only cast Blade Dance if you will hit multiple targets. This section show how many of your Blade Dance casts hit multiple targets.'
    return data
  end

  def self.fury_of_the_illidari
    data = cooldown_dps('Fury of the Illidari', [:illidari_damage, :illidari_extra_damage], ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    return false if !data

    data[:hash][:desc] += " Damage from Rage of the Illidari is shown in a lighter color."
    return data
  end

  def self.eye_beam_damage
    data = cooldown_dps('Eye Beam', [:eyebeam_damage, :eyebeam_extra_damage], ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    return false if !data

    data[:hash][:desc] += " Anguish damage is shown in a lighter color."
    return data
  end
  
  def self.metamorphosis_damage
    return cooldown_dps('Metamorphosis', :metamorphosis_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.chaos_blades_damage
    return false if @fp.talent(6) != 'Chaos Blades'
    data = cooldown_dps('Chaos Blades', :chaosblades_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    return false if !data
    
    data[:hash][:desc] = "The total amount of damage you dealt with Chaos Blades. Auto-attack damage is increased by 200% (shown as Chaos Blades), and all other damage is increased by #{@fp.mastery_percent.round(2)}% (mastery)."
    return data
  end

  def self.fel_barrage_damage
    return false if @fp.talent(6) != 'Fel Barrage'
    return cooldown_dps('Fel Barrage', :felbarrage_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

end