class DisplaySection

  def self.number_to_human(num)
    return ActionController::Base.helpers.number_to_human(num)
  end

  def self.bar_width(num, max)
    return 10 if num.nil? || num == 0
    return 100 if max.nil? || max == 0
    return [100,[100 * num / max, 10].max].min
  end

  def self.boss_data(fps, hashes)
    data = []
    hashes.each_with_index do |fp_hashes, fp_num|
      fp_hashes = fp_hashes.map{|hash| hash ? hash[:hash] : false}
      full_hashes = fp_hashes.reject{|hash| !hash}
      next if full_hashes.empty?
      fp_hashes.each_with_index do |section_hash, section_num|
        next if !section_hash
        data[section_num] ||= {
          title: section_hash[:title],
          desc: section_hash[:desc],
          sub_bars: [],
        }
        section_hash[:fp] = fps[fp_num]
        data[section_num][:sub_bars] << section_hash
      end

    end

    data.compact!
    data.each do |section_data|
      if section_data[:sub_bars].first.has_key?(:val)
        if section_data[:sub_bars].first.has_key?(:fight_time)
          max_width = section_data[:sub_bars].map{|hash| hash[:val].to_i / hash[:fight_time].to_i rescue 0}.max
        else
          max_width = section_data[:sub_bars].map{|hash| hash[:val].to_i}.max
        end
        if max_width > 0
          section_data[:sub_bars].each do |hash|
            val = hash.has_key?(:fight_time) ? (hash[:val].to_i / hash[:fight_time].to_i rescue 0) : hash[:val].to_i
            if hash.has_key?(:white_bar_width)
              hash[:white_bar_width] = bar_width(val, max_width)
            elsif hash.has_key?(:white_bar)
              # do nothing
            elsif hash.has_key?(:light_bar_width)
              hash[:light_bar_width] = bar_width(val, max_width)
            else
              hash[:main_bar_width] = bar_width(val, max_width)
            end
          end
        end
      end
    end

    return data

  end

  def self.abc
    hash = {
      title: 'Always Be Casting (Experimental)',
      desc: 'You should do your best to minimize downtime without casts (although 100% is unrealistic), by starting casts directly after the previous cast has finished, and by filling your GCDs with instant casts while moving. This section shows how much downtime you had over the course of the fight. The dropdown list shows cancelled casts, as well as periods of downtime that lasted more than 1 second.',
      white_bar: true,
      main_bar_width: 100 * (@fp.fight_time - @fp.resources_hash[:abc_wasted].to_f) / @fp.fight_time,
      main_bar_text: "#{@fp.fight_time - @fp.resources_hash[:abc_wasted].to_i}/#{@fp.fight_time}",
      main_text: "#{@fp.resources_hash[:abc_wasted]} seconds of downtime",
      dropdown: {id: 'abc'},
      labels: ['Time', 'Spell', 'Downtime before cast'],
      rows: @fp.resources_hash[:abc_fails].nil? ? nil : @fp.resources_hash[:abc_fails].map{|row| [{value: @fp.event_time(row[:timestamp], true)}, {value: row[:name]}, {value: (row[:cancelled] ? "Cast cancelled" : "#{row[:wasted]} seconds")}]},
    }
    return {partial: 'fight_parses/shared/table', hash: hash} 
  end

  # name = 'Buff Name'
  # uptime = @fp.kpi_hash[:buff_uptime].to_i
  # score = 100 * uptime / (@fp.ended_at - @fp.started_at)
  # buff = @fp.buff_parses.where(name: 'Buff Name').first
  def self.buff_stacks_graph(name, uptime, score = nil)
    buff = @fp.buff_parses.where(name: name).first
    return false if buff.nil? || uptime == 0
    hash = {
        title: "#{name} Uptime",
        desc: "The duration that you had #{name} active. A red area means #{name} was not active.",
        white_bar: true,
        main_bar_width: bar_width(uptime, @fp.ended_at - @fp.started_at),
        main_bar_text: "#{uptime / (10 * @fp.fight_time) rescue 0}%",
        main_text: "#{uptime / 1000}s / #{@fp.fight_time}s",
        buff: buff,
      } 
    if score.nil?
      hash[:desc] += " 100% is unrealisitic, but try to maintain this buff as much as possible."
    else
      hash[:label] = score >= 95 ? 'good' : score >= 85 ? 'ok' : 'bad'
    end
    if buff.kpi_hash.has_key?(:target_stacks)
      target_stacks = buff.kpi_hash[:target_stacks].to_i
      hash[:desc] = "The duration that you had #{name} at #{target_stacks} stacks. Try to maintain this buff as much as possible. A red area means #{name} was not active, and an orange area means that it was at less than #{target_stacks} stacks."
      hash[:stacks] = target_stacks
    end
    return {hash: hash} if @boss
    return {partial: "fight_parses/shared/stacks_graph", hash: hash}
  end

  def self.external_buff_graphs(name, slug, options = {})
  hash = {
    title: "#{name} Uptime",
    desc: "The percentage of time #{name} was active on friendly targets.",
    dropdown: {id: slug},
    white_bar: true,
    main_bar_width: @fp.buff_upratio(slug),
    main_bar_text: "#{@fp.buff_upratio(slug)}% uptime",
    main_text: @fp.buff_upratio_s(slug),
  }
  if options[:target_uptime]
    hash[:desc] += "  Aim for #{options[:target_uptime]}% uptime."
    score = 100 - (options[:target_uptime] - @fp.buff_upratio(slug))
    hash[:label] = (score >= 95 ? 'good' : score >= 85 ? 'ok' : 'bad')
  else
    hash[:desc] += "  Try to maximize uptime on tanks and other priority targets."
  end

  return {hash: hash} if @boss

  buffs = @fp.external_buff_parses.where(name: name)
  hash[:sub_bar_type] = 'debuff'
  hash[:sub_bars] = buffs.map{|item| 
    {
      debuff: item,
      label: item.target_name,
      id: "debuff-#{item.id}-#{item.target_id}",
      sub_text: item.upratio_s,
      hide_down: true,
    }
  }
  return {partial: 'fight_parses/shared/section', hash: hash}
end

  def self.casts
    hash = {
      title: 'Cast Efficiency',
      desc: "These are your key spells that should be cast as often as possible. Make sure you are casting them on cooldown. Your cast score is determined by a weighted average, with more emphasis placed on abilities with longer cooldown times.",
      label: (@fp.kpi_hash[:casts_score].to_i >= 95 ? 'good' : @fp.kpi_hash[:casts_score].to_i >= 85 ? 'ok' : 'bad'),
      white_bar: true,
      main_bar_width: @fp.kpi_hash[:casts_score],
      main_bar_text: "#{@fp.kpi_hash[:casts_score]}%",
      main_text: "#{@fp.kpi_hash[:casts_score]}% Efficiency",
      casts_score: @fp.kpi_hash[:casts_score]
    }
    if @fp.kpi_hash[:dead_time].to_i > 0
      hash[:desc] += " This does not account for the #{@fp.kpi_hash[:dead_time].to_i / 1000} seconds you were dead."
    end
    return {hash: hash} if @boss

    hash[:spells] = @fp.track_casts.each.map{|key, hash| 
      {
        label: key,
        casts: (@fp.casts_hash[key] || []),
        max_casts: @fp.casts_possible(hash),
        cd: hash[:cd],
        optional: hash[:optional]
      }
    }
    return {partial: 'fight_parses/shared/casts_table', hash: hash}
  end

  # name = 'Cooldown'
  # slug = :cooldown_reduced
  # dropdown_headers = ['Enemy', 'Hits', 'Damage Done']
  # dropdown_keys = [:name, [:hits, :extra_hits], :damage]
  def self.cooldown_damage_reduction(name, slug, dropdown_headers, dropdown_keys)
    bar_key = name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') + '-w'
    hash = {
      title: "#{name} Effectiveness",
      desc: "The total amount of damage mitigated through #{name}.",
      bar_key: 'cd-w',
      val: @fp.cooldowns_hash[slug].to_i,
      fight_time: @fp.fight_time,
      main_bar_text: number_to_human(@fp.cooldowns_hash[slug].to_i),
      main_text: "#{number_to_human(@fp.cooldowns_hash[slug].to_i)} mitigated",
    }
    return {hash: hash} if @boss

    hash[:sub_bars] = []
    cooldowns = @fp.cooldown_parses.where(name: name)
    cooldowns.each do |item|
      sub_bar = {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:reduced_amount].to_i,
        text: number_to_human(item.kpi_hash[:reduced_amount].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:reduced_amount].to_i)} dmg",
      }
      if dropdown_headers && dropdown_keys
        sub_bar[:dropdown] = {
          id: "#{bar_key}-#{item.id}",
          headers: dropdown_headers,
          content: [],
        }
        item.details_hash.each do |k, hash|
          dropdown_data = []
          dropdown_keys.each do |key|
            if key.is_a?(Array)
              dropdown_data << number_to_human(key.map{|k| hash[k].to_i}.sum)
            elsif hash[key].is_a?(Integer)
              dropdown_data << number_to_human(hash[key])
            else
              dropdown_data << hash[key]
            end
          end
          sub_bar[:dropdown][:content] << dropdown_data
        end
      end
      hash[:sub_bars] << sub_bar
    end
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  # name = 'Cooldown'
  # slug = :cooldown_damage
  # dropdown_headers = ['Enemy', 'Hits', 'Damage Done']
  # dropdown_keys = [:name, [:hits, :extra_hits], :damage]
  def self.cooldown_dps(name, slug, dropdown_headers = nil, dropdown_keys = nil)
    bar_key = name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') + '-w'
    if slug.is_a?(Array)
      hash = {
        title: "#{name} Damage",
        desc: "The total amount of damage you dealt with #{name}.",
        bar_key: 'cd-w',
        val: @fp.cooldowns_hash[slug[0]].to_i + @fp.cooldowns_hash[slug[1]].to_i,
        light_bar_width: 100,
        main_bar_width: bar_width(@fp.cooldowns_hash[slug[0]].to_i, @fp.cooldowns_hash[slug[0]].to_i + @fp.cooldowns_hash[slug[1]].to_i),
        fight_time: @fp.fight_time,
        main_bar_text: number_to_human(@fp.cooldowns_hash[slug[0]].to_i + @fp.cooldowns_hash[slug[1]].to_i),
        main_text: "#{number_to_human(@fp.cooldowns_hash[slug[0]].to_i)} damage (#{number_to_human(@fp.cooldowns_hash[slug[1]].to_i)} extra)",
      }
      hash[:main_bar_text] = number_to_human((@fp.cooldowns_hash[slug[0]].to_i + @fp.cooldowns_hash[slug[1]].to_i) / @fp.fight_time) + " dps" if @boss
    else
      hash = {
        title: "#{name} Damage",
        desc: "The total amount of damage you dealt with #{name}.",
        bar_key: 'cd-w',
        val: @fp.cooldowns_hash[slug].to_i,
        fight_time: @fp.fight_time,
        main_bar_text: number_to_human(@fp.cooldowns_hash[slug].to_i),
        main_text: "#{number_to_human(@fp.cooldowns_hash[slug].to_i)} damage",
      }
      hash[:main_bar_text] = number_to_human(@fp.cooldowns_hash[slug].to_i / @fp.fight_time) + " dps" if @boss
    end
    
    return {hash: hash}  if @boss

    hash[:sub_bars] = []
    cooldowns = @fp.cooldown_parses.where(name: name)
    cooldowns.each do |item|
      if item.kpi_hash.has_key?(:extra_damage)
        sub_bar = {
          item: item,
          label: item.time_s, 
          bar_key: bar_key,
          val: item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i,
          fight_time: @fp.fight_time,
          light_bar_width: 100,
          width: bar_width(item.kpi_hash[:damage_done].to_i, item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i),
          text: number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i),
          sub_text: "#{number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:extra_damage].to_i)} dmg",
        }
      elsif item.kpi_hash.has_key?(:pet_damage_done)
        sub_bar = {
          item: item,
          label: item.time_s, 
          bar_key: bar_key,
          val: item.kpi_hash[:damage_done].to_i + item.kpi_hash[:pet_damage_done].to_i,
          fight_time: @fp.fight_time,
          light_bar_width: 100,
          width: bar_width(item.kpi_hash[:damage_done].to_i, item.kpi_hash[:damage_done].to_i + item.kpi_hash[:pet_damage_done].to_i),
          text: number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:pet_damage_done].to_i),
          sub_text: "#{number_to_human(item.kpi_hash[:damage_done].to_i + item.kpi_hash[:pet_damage_done].to_i)} dmg",
        }
      else
        sub_bar = {
          item: item,
          label: item.time_s, 
          bar_key: bar_key,
          val: item.kpi_hash[:damage_done].to_i,
          text: number_to_human(item.kpi_hash[:damage_done].to_i),
          sub_text: "#{number_to_human(item.kpi_hash[:damage_done].to_i)} dmg",
        }
      end
      if dropdown_headers && dropdown_keys
        sub_bar[:dropdown] = {
          id: "#{bar_key}-#{item.id}",
          headers: dropdown_headers,
          content: [],
        }
        item.details_hash.each do |k, hash|
          dropdown_data = []
          dropdown_keys.each do |key|
            if key.is_a?(Array)
              dropdown_data << key.map{|k| hash[k].to_i}.sum
            else
              dropdown_data << hash[key]
            end
          end
          sub_bar[:dropdown][:content] << dropdown_data
        end
        sub_bar[:dropdown][:content].sort!{|a, b| b.last <=> a.last}
      end
      hash[:sub_bars] << sub_bar
    end
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.cooldown_timeline
    return false if @boss

    cooldowns_map = {'potion' => {}, 'proc' => {}, 'pet' => {}, 'cd' => {}, 'external' => {}, 'external_absorb' => {}}
    @fp.cooldown_parses.each do |cooldown|
      cooldowns_map[cooldown.cd_type] ||= {}
      cooldowns_map[cooldown.cd_type][cooldown.name] ||= []
      cooldowns_map[cooldown.cd_type][cooldown.name] << cooldown
    end
    hash = {
      title: 'Cooldown Timings',
      desc: 'Do your best to line up cooldowns to maximize DPS.',
      sub_bars: @fp.cooldown_timeline_bars,
      cooldowns_map: cooldowns_map,
    } 
    return {partial: 'fight_parses/shared/cooldown_timeline', hash: hash}
  end

  def self.damage_taken
    hash = {
      title: 'Damage Taken per Second',
      desc: 'This is the total damage (divided by fight time) that actually reduced your HP. Absorbs are not included.',
      val: @fp.dtps,
      fight_time: @fp.fight_time,
      main_bar_width: bar_width(@fp.dtps, @fp.max_basic_bar),
      main_bar_text: "#{number_to_human(@fp.dtps)}/s",
      main_text: "#{number_to_human(@fp.kpi_hash[:damage_taken].to_i)} total damage taken",
    }
    return {hash: hash} if @boss

    kpi_parse = @fp.kpi_parses.where(name: 'damage_taken').first
    max_dmg_taken = kpi_parse.details_hash.values.map{|item| item[:amount]}.max.to_i rescue 0

    hash[:dropdown] = {id: 'dmg_taken'}
    hash[:sub_bars] = kpi_parse.details_hash.to_a.sort{|a, b| b[1][:amount].to_i <=> a[1][:amount].to_i}.map{|name, item| 
      {
        label: name,
        width: bar_width(item[:amount].to_i, max_dmg_taken),
        text: number_to_human(item[:amount].to_i),
        sub_text: "#{number_to_human(item[:amount].to_i)} damage",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.death
    return false if @boss
    death = @fp.kpi_parses.where(name: 'death').first
    return false if death.nil? || death.kpi_hash[:death_count].to_i == 0
    hash = {deaths: death.details_hash[:deaths]}
    return {partial: 'fight_parses/shared/deaths', hash: hash}
  end

  def self.debuff_graphs(name, slug, options = {})
    percent = @fp.debuff_upratio(slug)
    hash = {
      title: "#{name} Uptime",
      desc: "The percentage of time #{name} was active on targets you were attacking. A red area means that you were attacking an enemy without #{name} active#{options[:target_stacks] ? ", and a light blue area means it wasn't at #{options[:target_stacks]} stacks" : ""}.",
      dropdown: {id: slug},
      white_bar: true,
      main_bar_width: percent,
      main_bar_text: @fp.debuff_upratio_s(slug),
      main_text: @fp.debuff_upratio_s(slug),
    }
    if options[:no_score]
      hash[:desc] += "  100% may not be realistic, but try to maximize uptime."
    else
      hash[:desc] += "  Aim for 100% uptime on #{options[:single_target] ? 'your primary target' : 'all targets'}."
      hash[:label] = (percent >= 95 ? 'good' : percent >= 85 ? 'ok' : 'bad')
    end

    return {hash: hash} if @boss

    debuffs = @fp.debuff_parses.where(name: name)
    hash[:sub_bar_type] = 'debuff'
    hash[:sub_bars] = debuffs.map{|item| 
      {
        debuff: item,
        label: item.target_name,
        id: "debuff-#{item.id}-#{item.target_id}",
        sub_text: item.upratio_s,
        stacks: options[:target_stacks],
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.dps
    hash = {
      title: 'Damage per Second',
      desc: 'Total damage / Fight time.',
      val: @fp.kpi_hash[:player_damage_done].to_i,
      fight_time: @fp.fight_time,
      main_bar_width: 100,
      main_bar_text: "#{number_to_human(@fp.dps)} dps",
      main_text: "#{number_to_human(@fp.kpi_hash[:player_damage_done].to_i)} total damage",
    }
    return {hash: hash} if @boss

    kpi_parse = @fp.kpi_parses.where(name: 'dps').first
    max_dps = kpi_parse.details_hash.values.map{|item| item[:damage]}.max.to_i rescue 0
    hash[:dropdown] = {id: 'dps'}
    hash[:sub_bars] = kpi_parse.nil? ? nil : kpi_parse.details_hash.values.sort{|a, b| b[:damage].to_i <=> a[:damage].to_i}.map{|item| 
      {
        label: item[:name],
        width: bar_width(item[:damage].to_i, max_dps),
        text: number_to_human(item[:damage].to_i),
        sub_text: "#{number_to_human(item[:damage].to_i)} damage",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash}
  end
  
  def self.dps_with_pet
    hash = {
      title: 'Damage per Second',
      desc: 'Total damage / Fight time. Pet damage is shown with a separate color',
      val: @fp.kpi_hash[:player_damage_done].to_i + @fp.kpi_hash[:pet_damage_done].to_i,
      fight_time: @fp.fight_time,
      light_bar_width: 100,
      main_bar_width: bar_width(@fp.kpi_hash[:player_damage_done].to_i, @fp.kpi_hash[:player_damage_done].to_i + @fp.kpi_hash[:pet_damage_done].to_i),
      main_bar_text: "#{number_to_human(@fp.dps)} dps",
      main_text: "#{number_to_human(@fp.kpi_hash[:player_damage_done].to_i + @fp.kpi_hash[:pet_damage_done].to_i)} total damage (#{number_to_human(@fp.kpi_hash[:pet_damage_done].to_i)} pet)",
    }
    return {hash: hash} if @boss

    kpi_parse = @fp.kpi_parses.where(name: 'dps').first
    max_dps = kpi_parse.details_hash.values.map{|item| item[:damage]}.max.to_i rescue 0
    hash[:dropdown] = {id: 'dps'}
    hash[:sub_bars] = kpi_parse.nil? ? nil : kpi_parse.details_hash.values.sort{|a, b| b[:damage].to_i <=> a[:damage].to_i}.map{|item| 
      {
        label: item[:name],
        width: bar_width(item[:damage].to_i, max_dps),
        text: number_to_human(item[:damage].to_i),
        sub_text: "#{number_to_human(item[:damage].to_i)} damage",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.external_healing
    hash = {
      title: 'External Healing per Second',
      desc: 'The total amount (divided by fight time) that other sources healed you. Absorbs are shown with a separate color.',
      val: @fp.ehps,
      fight_time: @fp.fight_time,
      light_bar_width: bar_width(@fp.ehps, @fp.max_basic_bar),
      main_bar_width: bar_width(@fp.kpi_hash[:external_heal].to_i, @fp.kpi_hash[:external_heal].to_i + @fp.kpi_hash[:external_absorb].to_i),
      main_bar_text: "#{number_to_human(@fp.ehps)}/s",
      main_text: "#{number_to_human(@fp.kpi_hash[:external_heal].to_i)} healed, #{number_to_human(@fp.kpi_hash[:external_absorb].to_i)} absorbed",
    }
    return {hash: hash} if @boss

    kpi_parse = @fp.kpi_parses.where(name: 'external_healing').first
    max_external_healing = kpi_parse.details_hash.values.map{|item| item[:absorb] + item[:heal]}.max.to_i rescue 0

    hash[:dropdown] = {id: 'external_healing'}
    hash[:sub_bars] = kpi_parse.details_hash.to_a.sort{|a, b| b[1][:absorb].to_i + b[1][:heal].to_i <=> a[1][:absorb].to_i + a[1][:heal].to_i}.map{|name, item| 
      {
        label: name,
        light_bar_width: bar_width(item[:absorb].to_i + item[:heal].to_i, max_external_healing),
        width: bar_width(item[:heal].to_i, item[:absorb].to_i + item[:heal].to_i),
        text: number_to_human(item[:absorb].to_i + item[:heal].to_i),
        sub_text: "#{number_to_human(item[:absorb].to_i)} absorb, #{number_to_human(item[:heal].to_i)} heal",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.healing
    hash = {
      title: 'Healing Done',
      desc: 'Total healing done. Overhealing is shown as the white part of the bar.',
      bar_key: 'basic-w',
      val: @fp.kpi_hash[:healing_done].to_i + @fp.kpi_hash[:overhealing_done].to_i,
      white_bar: true,
      main_bar_width: bar_width(@fp.kpi_hash[:healing_done].to_i, @fp.kpi_hash[:healing_done].to_i + @fp.kpi_hash[:overhealing_done].to_i),
      main_bar_text: "#{number_to_human(@fp.kpi_hash[:healing_done].to_i / @fp.fight_time)}/s",
      main_text: "#{number_to_human(@fp.kpi_hash[:healing_done].to_i)} healing (#{number_to_human(@fp.kpi_hash[:overhealing_done].to_i)} overhealing)"
    }
    return {hash: hash} if @boss

    kpi_parse = @fp.kpi_parses.where(name: 'healing_done').first
    max_healing = kpi_parse.details_hash.values.map{|item| item[:heal].to_i + item[:overheal].to_i}.max.to_i rescue 0
    hash[:dropdown] = {id: 'healing'}

    hash[:sub_bars] = kpi_parse.nil? ? nil : kpi_parse.details_hash.values.sort{|a, b| b[:heal].to_i <=> a[:heal].to_i }.map{|item| 
      {
        label: item[:name],
        white_bar: true,
        white_bar_width: bar_width(item[:heal].to_i + item[:overheal].to_i, max_healing),
        width: bar_width(item[:heal].to_i, item[:heal].to_i + item[:overheal].to_i),
        text: number_to_human(item[:heal].to_i),
        sub_text: "#{number_to_human(item[:heal].to_i)} healing (#{number_to_human(item[:overheal].to_i)} overhealing)",
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.healing_buff_cooldown(name, slug)
    hash = {
      title: "#{name} Healing",
      desc: "The total amount of extra healing provided by #{name}. Try to avoid overhealing.",
      bar_key: 'heal-w',
      val: @fp.cooldowns_hash["#{slug}_healing".to_sym].to_i + @fp.cooldowns_hash["#{slug}_overhealing".to_sym].to_i,
      white_bar: true,
      main_bar_width: bar_width(@fp.cooldowns_hash["#{slug}_healing".to_sym].to_i, @fp.cooldowns_hash["#{slug}_healing".to_sym].to_i + @fp.cooldowns_hash["#{slug}_overhealing".to_sym].to_i),
      main_bar_text: number_to_human(@fp.cooldowns_hash["#{slug}_healing".to_sym].to_i),
      main_text: "#{number_to_human(@fp.cooldowns_hash["#{slug}_healing".to_sym].to_i)} healing, #{number_to_human(@fp.cooldowns_hash["#{slug}_overhealing".to_sym].to_i)} overhealing"
    } 
    return {hash: hash} if @boss
    
    cooldowns = @fp.cooldown_parses.where(name: name)
    bar_key = slug + '-w'
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:healing_increase].to_i + item.kpi_hash[:overhealing_increase].to_i,
        white_bar: true,
        width: bar_width(item.kpi_hash[:healing_increase].to_i, item.kpi_hash[:healing_increase].to_i + item.kpi_hash[:overhealing_increase].to_i),
        text: number_to_human(item.kpi_hash[:healing_increase].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:healing_increase].to_i)} healing, #{number_to_human(item.kpi_hash[:overhealing_increase].to_i)} overhealing",
        dropdown: {
          id: "#{slug}-#{item.id}",
          headers: ['Player', 'Healing Done', 'Overhealing Done', 'Hits'],
          content: item.details_hash.values.reject{|v| v[:healing].to_i == 0 && v[:overhealing].to_i}.sort{|a, b| b[:healing].to_i <=> a[:healing].to_i}.map{|hash| [hash[:name], hash[:healing], hash[:overhealing], hash[:hits]]}
        }
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.healing_cooldown(name, slug)
    hash = {
      title: "#{name} Healing",
      desc: "The total amount of healing provided by #{name}. Try to avoid overhealing.",
      bar_key: 'heal-w',
      val: @fp.cooldowns_hash["#{slug}_healing".to_sym].to_i + @fp.cooldowns_hash["#{slug}_overhealing".to_sym].to_i,
      white_bar: true,
      main_bar_width: bar_width(@fp.cooldowns_hash["#{slug}_healing".to_sym].to_i, @fp.cooldowns_hash["#{slug}_healing".to_sym].to_i + @fp.cooldowns_hash["#{slug}_overhealing".to_sym].to_i),
      main_bar_text: number_to_human(@fp.cooldowns_hash["#{slug}_healing".to_sym].to_i),
      main_text: "#{number_to_human(@fp.cooldowns_hash["#{slug}_healing".to_sym].to_i)} healing, #{number_to_human(@fp.cooldowns_hash["#{slug}_overhealing".to_sym].to_i)} overhealing"
    } 
    return {hash: hash} if @boss
    
    cooldowns = @fp.cooldown_parses.where(name: name)
    bar_key = slug + '-w'
    hash[:sub_bars] = cooldowns.nil? ? nil : cooldowns.map{|item| 
      {
        label: item.time_s, 
        bar_key: bar_key,
        val: item.kpi_hash[:healing_done].to_i + item.kpi_hash[:overhealing_done].to_i,
        white_bar: true,
        width: bar_width(item.kpi_hash[:healing_done].to_i, item.kpi_hash[:healing_done].to_i + item.kpi_hash[:overhealing_done].to_i),
        text: number_to_human(item.kpi_hash[:healing_done].to_i),
        sub_text: "#{number_to_human(item.kpi_hash[:healing_done].to_i)} healing, #{number_to_human(item.kpi_hash[:overhealing_done].to_i)} overhealing",
        dropdown: {
          id: "#{slug}-#{item.id}",
          headers: ['Player', 'Healing Done', 'Overhealing Done', 'Hits'],
          content: item.details_hash.values.reject{|v| v[:healing].to_i == 0 && v[:overhealing].to_i == 0}.sort{|a, b| b[:healing].to_i <=> a[:healing].to_i}.map{|hash| [hash[:name], hash[:healing], hash[:overhealing], hash[:hits]]}
        }
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.healing_per_mana
    hash = {
      title: 'Healing Efficiency per Mana spent',
      desc: 'The amount of healing you did with each ability (not including overhealing), weighed by total mana spent. Spells are ordered by total mana spent. Try to avoid wasting mana on costly spells with lots of overhealing.',
      white_bar: true,
      main_bar_width: bar_width(@fp.kpi_hash[:healing_done].to_i, @fp.kpi_hash[:healing_done].to_i + @fp.kpi_hash[:overhealing_done].to_i),
      main_bar_text: number_to_human(1000 * @fp.kpi_hash[:healing_done].to_i / @fp.resources_hash[:mana_spent]),
      main_text: "#{number_to_human(1000 * @fp.kpi_hash[:healing_done].to_i / @fp.resources_hash[:mana_spent])} healing per 1k mana"
    }
    return {hash: hash} if @boss

    min_healing = @fp.resources_hash[:heal_per_mana].nil? ? 0 : @fp.resources_hash[:heal_per_mana].values.map{|hash| 1000 * (hash[:healing].to_i + hash[:overhealing].to_i) / hash[:mana_spent].to_i}.min.to_i
    max_healing = [@fp.resources_hash[:heal_per_mana].nil? ? 0 : @fp.resources_hash[:heal_per_mana].values.map{|hash| 1000 * (hash[:healing].to_i + hash[:overhealing].to_i) / hash[:mana_spent].to_i}.max.to_i, min_healing * 7].min.to_i
    hash[:dropdown] = {id: 'healing'}
    hash[:sub_bars] = @fp.resources_hash[:heal_per_mana].nil? ? nil : @fp.resources_hash[:heal_per_mana].values.sort{|a, b| b[:mana_spent].to_i <=> a[:mana_spent].to_i }.map{|item| 
      {
        label: item[:name],
        white_bar: true,
        white_bar_width: bar_width(1000 * (item[:healing].to_i + item[:overhealing].to_i) / item[:mana_spent].to_i, max_healing),
        width: bar_width(item[:healing].to_i, item[:healing].to_i + item[:overhealing].to_i),
        text: "#{number_to_human(1000 * item[:healing].to_i / item[:mana_spent].to_i)}",
        sub_text: "#{number_to_human(1000 * item[:healing].to_i / item[:mana_spent].to_i)} hpm, #{number_to_human(item[:mana_spent].to_i)} mana spent",
      }
    } 
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.health_graph
    return false if @boss
    return {partial: 'fight_parses/shared/hp_graph'}
  end

  def self.proc_table(name, used, gained, fail_labels = nil, fail_rows = nil)
    hash = {
      title: "#{name} Proc Usage",
      desc: "This section shows how well you used your #{name} procs",
      white_bar: true,
      main_bar_width: bar_width(used, gained),
      main_bar_text: "#{used}/#{gained}",
      main_text: "#{gained - used} missed",
    }
    return {hash: hash} if @boss

    hash[:labels] = fail_labels
    hash[:rows] = fail_rows.nil? ? nil : fail_rows.map{|fail| [{class: fail[:class] || 'red', value: @fp.event_time(fail[:timestamp], true)}, {value: fail[:msg]}]}

    return {partial: 'fight_parses/shared/table', hash: hash}
  end

  def self.proc_usage(name, used, gained, casts = nil)
    bar_key = name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') + '-w'
    hash = {
      title: "#{name} Proc Usage",
      desc: "This section shows how well you used your #{name} procs",
      white_bar: true,
      main_bar_width: bar_width(used, gained),
      main_bar_text: "#{used}/#{gained}",
      main_text: "#{gained - used} wasted",
    }
    return {hash: hash} if @boss

    if !casts.nil?
      hash[:sub_bars] = casts.values.sort{|a, b| b[:casts].to_i <=> a[:casts].to_i}.map{|item| 
        {
          label: item[:name],
          bar_key: bar_key,
          val: item[:casts].to_i,
          text: "#{item[:casts].to_i}",
          sub_text: "#{item[:casts].to_i} casts",
        }
      } 
    end
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end

  def self.raid_health_graph
    return false if @boss
    return {partial: 'fight_parses/shared/raid_hp', resize: 'hp-w'}
  end

  def self.resource_cap(type)
    score = 100 * (@fp.fight_time - @fp.resources_hash[:capped_time].to_i) / @fp.fight_time
    hash = {
      title: "Time not #{type}-Capped",
      desc: "The percent of the fight that you had less than max #{type}. Aim for 100%.",
      label: score >= 95 ? 'good' : score >= 90 ? 'ok' : 'bad',
      white_bar: true,
      main_bar_width: bar_width(@fp.fight_time - @fp.resources_hash[:capped_time].to_i, @fp.fight_time),
      main_bar_text: "#{@fp.fight_time - @fp.resources_hash[:capped_time].to_i}s",
      main_text: "#{@fp.fight_time - @fp.resources_hash[:capped_time].to_i}s / #{@fp.fight_time}s",
    } 
    return {hash: hash} if @boss
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.resource_damage(type)
    slug = type.downcase.strip.gsub(' ', '')
    hash = {
      title: "#{type} Usage",
      desc: "The amount of damage per #{type} you did with each ability. Spells are ordered by total #{type} spent. Try to spend #{type} on high-damage abilities as much as possible.",
      val: (@fp.resources_hash[:"#{slug}_damage".to_sym].to_i / @fp.resources_hash[:"#{slug}_spent".to_sym].to_i rescue 0),
      main_bar_width: 100,
      main_bar_text: "#{number_to_human(@fp.resources_hash[:"#{slug}_damage".to_sym].to_i / @fp.resources_hash[:"#{slug}_spent".to_sym].to_i) rescue 0} dmg/#{type}",
      main_text: "#{number_to_human(@fp.resources_hash[:"#{slug}_damage".to_sym].to_i / @fp.resources_hash[:"#{slug}_spent".to_sym].to_i) rescue 0} damage per #{type}",
    }
    return {hash: hash} if @boss

    bar_key = 'dpr-w'
    hash[:sub_bars] = @fp.resources_hash["#{slug}_spend".to_sym].nil? ? nil :@fp.resources_hash["#{slug}_spend".to_sym].values.sort{|a, b| b[:spent].to_i <=> a[:spent].to_i }.map{|item| 
      {
        label: item[:name],
        val: 1000 * item[:damage].to_i / item[:spent].to_i,
        bar_key: bar_key,
        text: "#{number_to_human(item[:damage].to_i / item[:spent].to_i)} damage/#{type}",
        sub_text: "#{number_to_human(item[:damage].to_i)} damage / #{item[:spent].to_i} #{type}",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: bar_key}
  end
 
  def self.resource_gain(type)
    slug = type.downcase.strip.gsub(' ', '')
    gain = (@fp.resources_hash["#{slug}_gain".to_sym] || @fp.resources_hash["#{slug}_gained".to_sym]).to_i
    waste = (@fp.resources_hash["#{slug}_waste".to_sym] || @fp.resources_hash["#{slug}_wasted".to_sym]).to_i
    abilities = @fp.resources_hash["#{slug}_abilities".to_sym]
    score = 100 * gain / (gain + waste) rescue 0
    hash = {
      title: "#{type} Gained",
      desc: "Avoid overcapping #{type} by not using #{type}-generating abilities that would put you over the maximum amount.",
      label: score == 100 ? 'good' : score >= 95 ? 'ok' : 'bad',
      fight_time: @fp.fight_time,
      white_bar: true,
      main_bar_width: bar_width(gain, gain + waste),
      main_bar_text: "#{gain}/#{gain + waste}",
      main_text: "#{waste} wasted",
    }
    return {hash: hash} if @boss

    hash[:sub_bars] = abilities.nil? ? nil : abilities.values.sort{|a, b| (b[:gain].to_i + b[:waste].to_i) <=> (a[:gain].to_i + a[:waste].to_i)}.map{|item| 
      {
        label: item[:name],
        white_bar: true,
        bar_key: "#{slug}-w",
        val: item[:gain].to_i + item[:waste].to_i,
        width: bar_width(item[:gain].to_i, item[:gain].to_i + item[:waste].to_i),
        text: "#{item[:gain].to_i}/#{item[:gain].to_i + item[:waste].to_i}",
        sub_text: "#{item[:waste].to_i} wasted",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash, resize: "#{slug}-w"}
  end

  def self.self_healing
    hash = {
      title: 'Self Healing per Second',
      desc: 'The total amount (divided by fight time) that you healed yourself. Absorbs are shown with a separate color.',
      val: @fp.shps,
      fight_time: @fp.fight_time,
      light_bar_width: bar_width(@fp.shps, @fp.max_basic_bar),
      main_bar_width: bar_width(@fp.kpi_hash[:self_heal].to_i, @fp.kpi_hash[:self_heal].to_i + @fp.kpi_hash[:self_absorb].to_i),
      main_bar_text: "#{number_to_human(@fp.shps)}/s",
      main_text: "#{number_to_human(@fp.kpi_hash[:self_heal].to_i)} healed, #{number_to_human(@fp.kpi_hash[:self_absorb].to_i)} absorbed",
    }
    return {hash: hash} if @boss

    kpi_parse = @fp.kpi_parses.where(name: 'self_healing').first
    max_self_healing = kpi_parse.details_hash.values.map{|item| item[:absorb] + item[:heal]}.max.to_i rescue 0

    hash[:dropdown] = {id: 'self_healing'}
    hash[:sub_bars] = kpi_parse.details_hash.to_a.sort{|a, b| b[1][:absorb].to_i + b[1][:heal].to_i <=> a[1][:absorb].to_i + a[1][:heal].to_i}.map{|name, item| 
      {
        label: name,
        light_bar_width: bar_width(item[:absorb].to_i + item[:heal].to_i, max_self_healing),
        width: bar_width(item[:heal].to_i, item[:absorb].to_i + item[:heal].to_i),
        text: number_to_human(item[:absorb].to_i + item[:heal].to_i),
        sub_text: "#{number_to_human(item[:absorb].to_i)} absorb, #{number_to_human(item[:heal].to_i)} heal",
      }
    }
    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.success_bars(score)
    hash = {
      title: 'Bars',
      desc: 'This shows how many times you did this well',
      label: (score >= 95 ? 'good' : score >= 85 ? 'ok' : 'bad'),
      white_bar: true,
      main_bar_width: score,
      main_bar_text: "#{score}%",
      main_text: "#{score}%",
    }
    return {hash: hash} if @boss

    return {partial: 'fight_parses/shared/section', hash: hash}
  end

  def self.table_with_bar(good_count, bad_count)
    hash = {
        title: 'Table',
        desc: 'This show how many times you did this well.',
        label: bad_count == 0 ? 'good' : 'bad',
        fight_time: @fp.fight_time,
        white_bar: true,
        main_bar_width: bar_width(good_count, good_count + bad_count),
        main_bar_text: "#{100 * good_count / (good_count + bad_count) rescue 0}%",
        main_text: "#{good_count}/#{good_count + bad_count}",
        labels: [],
        rows: [],
      } 
    return {hash: hash} if @boss
    return {partial: 'fight_parses/shared/table', hash: hash}
  end

  

end