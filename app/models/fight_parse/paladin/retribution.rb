class FightParse::Paladin::Retribution < FightParse
  include Filterable
  self.table_name = :fp_paladin_ret

  def self.latest_patch
    return '7.2.5'
  end
  
  def self.latest_version
    return super * 1000 + 3
  end

  def self.latest_hotfix
    return super * 1000 + 0
  end

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
      hp_with_judgment: 0,
      hp_without_judgment: 0,
      hp_judgment_casts: {},
    }
    self.resources_hash = {
      holypower_gain: 0,
      holypower_waste: 0,
      holypower_abilities: {},
      holypower_spend: {},
      holypower_damage: 0,
      holypower_spent: 0,
      judgment_uptime: 0,
      judgment_downtime: 0,
    }
    self.cooldowns_hash = {
      avenging_damage: 0,
      crusade_damage: 0,
      crusade_avghp: 0,
    }
    @resources = {
      "r#{ResourceType::HOLYPOWER}" => 0,
      "r#{ResourceType::HOLYPOWER}_max" => self.max_holy,
    }
    @holy = 0
    @hp_casts = {}
    self.save
  end

  # getters

  def spell_name(id)
    return {
      20271 => 'Judgment',
      197277 => 'Judgment',
      85256 => 'Templar\'s Verdict',
      224266 => 'Templar\'s Verdict',
      205273 => 'Wake of Ashes',
      35395 => 'Crusader Strike',
      31884 => 'Avenging Wrath',
      224668 => 'Crusade',
      231895 => 'Crusade',
      217020 => 'Zeal',
      213757 => 'Execution Sentence',
      198034 => 'Divine Hammer',
      184575 => 'Blade of Justice',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    if talent(6) == 'Crusade'
      local['Crusade'] = {cd: 120}
    else
      local['Avenging Wrath'] = {cd: 120}
    end
    local['Wake of Ashes'] = {cd: 30}
    local['Execution Sentence'] = {cd: 20} if talent(0) == 'Execution Sentence'
    local['Judgment'] = {cd: (12 * self.haste_reduction_ratio)}
    if talent(3) == 'Divine Hammer'
      local['Divine Hammer'] = {cd: (12 * self.haste_reduction_ratio)}
    else
      local['Blade of Justice'] = {cd: (10.5 * self.haste_reduction_ratio)}
    end
    if talent(1) == 'Zeal'
      local['Zeal'] = {cd: (4.5 * self.haste_reduction_ratio), extra: 1}
    else
      local['Crusader Strike'] = {cd: (4.5 * self.haste_reduction_ratio), extra: 1}
    end
    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    if talent(6) == 'Crusade'
      bars['cd']['Crusade'] = {cd: (120 * self.haste_reduction_ratio)}
    else
      bars['cd']['Avenging Wrath'] = {cd: (120 * self.haste_reduction_ratio)}
    end
    return bars
  end

  def cooldown_abilities
    local = {
      'Avenging Wrath' => {kpi_hash: {damage_done: 0}},
      'Crusade' => {kpi_hash: {damage_done: 0, hp_spent: 0}},
    }
  end

  def dps_buff_abilities
    local = {
      'Avenging Wrath' => {percent: 0.35},
      'Crusade' => {percent: 1},
    }
  end

  def debuff_abilities
    local = {
      'Judgment' => {},
    }
    return local.merge super
  end

  def track_resources
    return [ResourceType::HOLYPOWER]
  end

  def max_holy
    return 5
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::HOLYPOWER
        @holy = [resource['amount'].to_i - resource['cost'].to_i, 0].max
        if resource['cost'].to_i > 0
          @hp_casts[ability_name] = event['timestamp']
          # mark that judgment was inactive, by default
          self.kpi_hash[:hp_without_judgment] += 1
          self.kpi_hash[:hp_judgment_casts][ability_name] ||= {name: ability_name, active: 0, inactive: 0}
          self.kpi_hash[:hp_judgment_casts][ability_name][:inactive] += 1
          # check if Crusade is active
          if @cooldowns['Crusade'][:active]
            @cooldowns['Crusade'][:cp].kpi_hash[:hp_spent] += resource['cost'].to_i
          end
          self.resources_hash[:holypower_spend][ability_name] ||= {name: ability_name, spent: 0, damage: 0}
          self.resources_hash[:holypower_spend][ability_name][:spent] += resource['cost'].to_i
        end
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::HOLYPOWER
      holypower_waste = [@holy + event['resourceChange'].to_i - self.max_holy, 0].max
      holypower_gain = event['resourceChange'].to_i - holypower_waste
      @holy += holypower_gain
      self.resources_hash[:holypower_gain] += holypower_gain
      self.resources_hash[:holypower_waste] += holypower_waste
      self.resources_hash[:holypower_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:holypower_abilities][ability_name][:gain] += holypower_gain
      self.resources_hash[:holypower_abilities][ability_name][:waste] += holypower_waste
    end
  end

  def deal_damage_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if self.resources_hash[:holypower_spend].has_key?(ability_name)
      self.resources_hash[:holypower_spend][ability_name][:damage] += event['amount'].to_i
    end
    if @hp_casts.has_key?(ability_name)
      # check if judgment was active
      if @debuffs['Judgment'].has_key?(target_key) && @debuffs['Judgment'][target_key][:active]
        # remove the default inactive, and record that judgment was active on a target
        self.kpi_hash[:hp_without_judgment] -= 1
        self.kpi_hash[:hp_with_judgment] += 1
        self.kpi_hash[:hp_judgment_casts][ability_name][:inactive] -= 1
        self.kpi_hash[:hp_judgment_casts][ability_name][:active] += 1
        @hp_casts.delete(ability_name)
      end
    end
  end

  def clean
    super
    self.resources_hash[:holypower_spend].each do |key, spell|
      self.resources_hash[:holypower_damage] += spell[:damage].to_i
      self.resources_hash[:holypower_spent] += spell[:spent].to_i
    end
    self.cooldowns_hash[:avenging_damage] = @kpis['Avenging Wrath'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:crusade_damage] = @kpis['Crusade'].map{|kpi| kpi[:damage_done]}.sum rescue 0
    self.cooldowns_hash[:crusade_avghp] = @kpis['Crusade'].map{|kpi| kpi[:hp_spent]}.sum / @kpis['Crusade'].count rescue 0
    self.debuff_parses.where(name: 'Judgment').each do |debuff|
      self.resources_hash[:judgment_uptime] += debuff.kpi_hash[:uptime].to_i
      self.resources_hash[:judgment_downtime] += debuff.kpi_hash[:downtime].to_i
    end
    self.save
  end

end