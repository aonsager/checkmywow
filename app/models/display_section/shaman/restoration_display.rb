class DisplaySection::Shaman::RestorationDisplay < DisplaySection

  @boss = false
  @fp = nil

  def self.show_section(category, fp, boss = false)
    @boss = boss
    @fp = fp
    case category
    when 'basic'
      return [
        healing,
        chain_heal,
        tidal_waves_procs,
        tidal_waves_usage,
        ancestral_vigor,
        death,
      ]
    when 'casts'
      return [
        casts,
      ]
    when 'resources'
      return [
        healing_per_mana,
        abc,
      ]
    when 'cooldowns'
      return [
        cooldown_timeline,
        healing_cooldown('Healing Tide Totem', 'healing_tide'),
        ascendance,
        ancestral_guidance,
        healing_cooldown('Gift of the Queen', 'queen'),
        cloudburst_totem,
      ]
    when 'raid_hp'
      return [
        raid_health_graph,
      ]
    end
  end

  def self.chain_heal
    data = proc_usage('Chain Heal', @fp.kpi_hash[:chain_heal_good].to_i, @fp.kpi_hash[:chain_heal_total].to_i)
    data[:hash][:title] = 'Chain Heal - Targets Hit'
    data[:hash][:desc] = 'The number of targets hit each time you cast Chain Heal. Do your best to hit at least 4 targets as often as possible.'
    return data if @boss
    bar_key = 'chainheal-w'
    if !@fp.kpi_hash[:chain_heal_hits].blank?
      data[:hash][:sub_bars] = @fp.kpi_hash[:chain_heal_hits].map{|hits, num| 
        {
          label: "#{hits} Players",
          bar_key: bar_key,
          val: num,
          text: "#{num}",
          sub_text: "#{num} casts",
        }
      } 
    end
    data[:resize] = bar_key
    return data
  end

  def self.tidal_waves_procs
    data = proc_usage('Tidal Waves', @fp.kpi_hash[:tidal_waves_used].to_i, @fp.kpi_hash[:tidal_waves_procs].to_i)
    data[:hash][:desc] = 'Avoid casting Riptides or Chain Heal when you are already at 2 stacks of Tidal Waves, as this will waste a stack. This section shows how many potential procs were lost.'
    missed = @fp.kpi_hash[:tidal_waves_procs].to_i - @fp.kpi_hash[:tidal_waves_used].to_i
    data[:hash][:label] = missed == 0 ? 'good' : missed <= 5 ? 'ok' : 'bad'
    return data
  end

  def self.tidal_waves_usage
    buffed = @fp.kpi_hash[:tidal_waves_spells]['Healing Wave'][:buffed].to_i + @fp.kpi_hash[:tidal_waves_spells]['Healing Surge'][:buffed].to_i rescue 0
    unbuffed = @fp.kpi_hash[:tidal_waves_spells]['Healing Wave'][:unbuffed].to_i + @fp.kpi_hash[:tidal_waves_spells]['Healing Surge'][:unbuffed].to_i rescue 0
    data = proc_usage('Tidal Waves', buffed, buffed + unbuffed)
    data[:hash][:desc] = 'Be sure to spend your Tidal Waves procs on either Healing Wave or Healing Surge. This shows the percentage of these spells\' casts that benefited from Tidal Waves.'
    return data if @boss
    bar_key = 'tidalwaves-w'
    data[:hash][:sub_bars] = @fp.kpi_hash[:tidal_waves_spells].nil? ? nil : @fp.kpi_hash[:tidal_waves_spells].map{|spell, hash| 
      {
        label: spell,
        bar_key: bar_key,
        val: hash[:buffed].to_i + hash[:unbuffed].to_i,
        white_bar: true,
        width: bar_width(hash[:buffed].to_i, hash[:buffed].to_i + hash[:unbuffed].to_i),
        text: "#{hash[:buffed].to_i}/#{hash[:buffed].to_i + hash[:unbuffed].to_i}",
        sub_text: "#{hash[:buffed].to_i}/#{hash[:buffed].to_i + hash[:unbuffed].to_i} casts buffed",
      }
    }
    data[:resize] = bar_key
    return data
  end

  def self.ancestral_vigor
    return false if @fp.talent(4) != 'Ancestral Vigor'
    return external_buff_graphs('Ancestral Vigor', :vigor)
  end

  def self.ascendance
    return false if @fp.talent(6) != 'Ascendance'
    return healing_buff_cooldown('Ascendance', 'ascendance')
  end

  def self.ancestral_guidance
    return false if @fp.talent(3) != 'Ancestral Guidance'
    return healing_cooldown('Ancestral Guidance', 'guidance')
  end

  def self.cloudburst_totem
    return false if @fp.talent(5) != 'Cloudburst Totem'
    return healing_cooldown('Cloudburst Totem', 'cloudburst')
  end

end