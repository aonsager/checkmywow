class DisplaySection::Mage::FrostDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        dps_with_pet,
        brain_freeze,
        winters_chill,
        fingers,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [

      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        icy_veins,
        rune_of_power,
        mirror_image,
        cooldown_dps('Frozen Orb', :frozen_orb_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage]),
        ray_of_frost,
      ]
    end
  end

  def self.brain_freeze
    data = proc_table('Brain Freeze', @fp.kpi_hash[:brain_freeze_used].to_i, @fp.kpi_hash[:brain_freeze_procs].to_i, ['Timestamp', 'Event'], @fp.kpi_hash[:brain_freeze_waste_details])
    data[:hash][:desc] += " Make sure you don't overwrite existing procs before gaining new ones."
    return data
  end

  def self.winters_chill
    data = proc_table('Winter\'s Chill', @fp.kpi_hash[:winters_chill_used].to_i, @fp.kpi_hash[:winters_chill_procs].to_i, ['Timestamp', 'Event'], @fp.kpi_hash[:winters_chill_waste_details])
    data[:hash][:desc] = ' Be sure to always cast Ice Lance immediately after applying Winter\'s Chill to avoid wasting the proc.'
    return data
  end

  def self.fingers
    data = proc_table('Fingers of Frost', @fp.kpi_hash[:fingers_gained].to_i - @fp.kpi_hash[:fingers_wasted].to_i, @fp.kpi_hash[:fingers_gained].to_i, ['Timestamp', 'Event'], @fp.kpi_hash[:fingers_waste_details])
    data[:hash][:title] = 'Fingers of Frost Usage'
    data[:hash][:desc] = ' Be sure to spend all of your Fingers of Frost before applying Winter\'s Chill, and avoid gaining additional stacks when you are already capped.'
    return data
  end
  
  def self.casts
    data = super
    data[:hash][:desc] += " Your T20 4-piece bonus reduced Frozen Orb\'s cooldown by #{@fp.resources_hash[:frozen_orb_cdr].to_i} seconds." if @fp.set_bonus(20) >= 4
    return data
  end

  def self.icy_veins
    data = cooldown_dps('Icy Veins', :icy_veins_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
    return data if @boss

    data[:hash][:sub_bars].each do |sub_bar|
      sub_bar[:sub_text] += " / #{sub_bar[:item].time} sec"
    end
    return data
  end

  def self.rune_of_power
    return false if @fp.talent(2) != 'Rune of Power'
    return cooldown_dps('Rune of Power', :rune_of_power_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.mirror_image
    return false if @fp.talent(2) != 'Mirror Image'
    return cooldown_dps('Mirror Image', :mirror_image_damage, ['Ability', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end

  def self.ray_of_frost
    return false if @fp.talent(0) != 'Ray of Frost'
    return cooldown_dps('Ray of Frost', :ray_of_frost_damage, ['Enemy', 'Hits', 'Damage Done'], [:name, :hits, :damage])
  end


end