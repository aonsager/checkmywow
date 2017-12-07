class FightParse::Rogue::Outlaw < FightParse
  include Filterable
  self.table_name = :fp_rogue_outlaw

  def init_vars
    super
    self.kpi_hash = {
      player_damage_done: 0,
      casts_score: 0,
      opportunity_procs: 0,
      opportunity_used: 0,
    }
    self.resources_hash = {
      capped_time: 0,
      combo_gain: 0,
      combo_waste: 0,
      combo_abilities: {},
      combo_spend: {},
      rollthebones_uptime: 0,
      rollthebones_stack_uptime: 0,
      ghostly_uptime: 0,
      slice_uptime: 0,
    }
    self.cooldowns_hash = {

    }
    @resources = {
      "r#{ResourceType::COMBOPOINTS}" => 0,
      "r#{ResourceType::COMBOPOINTS}_max" => self.max_combo,
    }
    @combo = 0
    self.save
  end

  # settings

  def self.latest_version
    return super * 1000 + 1
  end

  def self.latest_hotfix
    return super * 1000 + 1
  end

  def in_progress?
    return true
  end

  # getters

  def spell_name(id)
    return {
      193316 => 'Roll the Bones',
      199603 => 'Jolly Roger',
      193358 => 'Grand Melee',
      193357 => 'Shark Infested Waters',
      193359 => 'True Bearing',
      199600 => 'Buried Treasure',
      193356 => 'Broadsides',
      195627 => 'Opportunity',
      193315 => 'Saber Slash',
      197834 => 'Saber Slash',
      185763 => 'Pistol Shot',
      2098 => 'Run Through',
      202665 => 'Curse of the Dreadblades',
      202668 => 'Curse of the Dreadblades',
      193531 => 'Deeper Strategem',
      114015 => 'Anticipation',
      196937 => 'Ghostly Strike',
      5171 => 'Slice and Dice',
      13750 => 'Adrenaline Rush',
      1856 => 'Vanish',
      51690 => 'Killing Spree',
      185767 => 'Cannonball Barrage',
      202897 => 'Blunderbuss',
      202895 => 'Blunderbuss',
    }[id] || super(id)
  end

  def track_casts
    local = {}
    local['Adrenaline Rush'] = {cd: 180}
    local['Killing Spree'] = {cd: 120} if talent(5) == 'Killing Spree'
    # local['Vanish'] = {cd: 120}
    local['Curse of the Dreadblades'] = {cd: 90}
    local['Cannonball Barrage'] = {cd: 60} if talent(5) == 'Cannonball Barrage'

    return super.merge local
  end

  def cooldown_timeline_bars
    bars = super
    bars['cd']['Adrenaline Rush'] = {cd: 180}
    bars['cd']['Curse of the Dreadblades'] = {cd: 90}
    return bars
  end

  def uptime_abilities
    local = {
      'Opportunity' => {},
    }
    return super.merge local
  end

  def buff_abilities
    local = {
      'Roll the Bones' => {},
      'Slice and Dice' => {},
    }
    return super.merge local
  end

  def debuff_abilities
    local = {
      'Ghostly Strike' => {},
    }
    return local.merge super
  end

  def cooldown_abilities
    local = {
      'Adrenaline Rush' => {},
      'Killing Spree' => {},
      'Curse of the Dreadblades' => {},
      'Cannonball Barrage' => {},
    }
  end

  def track_resources
    return [ResourceType::COMBOPOINTS]
  end

  def show_resources
    return [ResourceType::ENERGY, ResourceType::COMBOPOINTS]
  end

  def max_combo
    return 6 if talent(2) == 'Deeper Strategem'
    return 8 if talent(2) == 'Anticipation'
    return 5
  end

  # event handlers

  def cast_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']

    if @uptimes['Opportunity'][:active] && ['Pistol Shot', 'Blunderbuss'].include?(ability_name)
      self.kpi_hash[:opportunity_used] += 1 
    end
  
    (event['classResources'] || []).each do |resource|
      if resource['type'] == ResourceType::ENERGY
        check_resource_cap(resource['amount'], resource['max'], event['timestamp']) 
      end
      if resource['type'] == ResourceType::COMBOPOINTS
        if resource['cost'].to_i > 0
          self.resources_hash[:combo_spend][ability_name] ||= {name: ability_name, combo: {1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0}}
          self.resources_hash[:combo_spend][ability_name][:combo][@combo] += 1 if self.resources_hash[:combo_spend][ability_name][:combo].has_key?(@combo)
        end
        @combo = [resource['amount'].to_i - resource['cost'].to_i, 0].max
      end
    end
  end

  def energize_event(event)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    if event['resourceChangeType'] == ResourceType::COMBOPOINTS
      if ability_name == 'Curse of the Dreadblades'
        combo_waste = @combo
        combo_gain = self.max_combo - @combo
      else
        combo_waste = [@combo + event['resourceChange'].to_i - self.max_combo, 0].max
        combo_gain = event['resourceChange'].to_i - combo_waste
      end
      @combo += combo_gain
      self.resources_hash[:combo_gain] += combo_gain
      self.resources_hash[:combo_waste] += combo_waste
      self.resources_hash[:combo_abilities][ability_name] ||= {name: ability_name, gain: 0, waste: 0}
      self.resources_hash[:combo_abilities][ability_name][:gain] += combo_gain
      self.resources_hash[:combo_abilities][ability_name][:waste] += combo_waste
    end
  end

  def gain_self_buff_event(event, refresh=false)
    super
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    self.kpi_hash[:opportunity_procs] += 1 if ability_name == 'Opportunity'
  end

  def clean
    super
    self.resources_hash[:ghostly_uptime] = @uptimes['Ghostly Strike'][:uptime] rescue 0
    self.resources_hash[:rollthebones_uptime] = @uptimes['Roll the Bones'][:uptime] rescue 0
    self.resources_hash[:slice_uptime] = @uptimes['Slice and Dice'][:uptime] rescue 0
    
    self.save
  end

end