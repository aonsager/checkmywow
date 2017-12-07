class FightParse < ActiveRecord::Base
  belongs_to :fight
  belongs_to :player, foreign_key: :player_id, primary_key: :player_id
  has_many :cooldown_parses, dependent: :destroy
  has_many :buff_parses, dependent: :destroy
  has_many :debuff_parses, dependent: :destroy
  has_many :external_cooldown_parses, dependent: :destroy
  has_many :external_buff_parses, dependent: :destroy
  has_many :kpi_parses, dependent: :destroy
  serialize :kpi_hash, Hash
  serialize :resources_hash, Hash
  serialize :cooldowns_hash, Hash
  serialize :casts_hash, Hash
  serialize :combatant_info, Hash
  enum status: [:unprocessed, :queued, :processing, :done, :failed, :empty]

  def log(msg, timestamp=nil)
    Resque.logger.info("#{timestamp.nil? ? '' : "[#{self.event_time(timestamp)}] "}#{msg}")
  end

  def init_vars
    self.kpi_hash = {
      player_damage_done: 0,
      pet_damage_done: 0,
      dead_time: 0,
    }
    self.resources_hash = {}
    self.cooldowns_hash = {}
    self.casts_hash = {}
    @uptimes = {}
    self.uptime_abilities.each do |name, hash| 
      @uptimes[name] = {active: false, uptime: 0}
    end
    @cooldowns = {}
    (self.cooldown_abilities.keys + self.dps_buff_abilities.keys + self.dps_abilities.keys).uniq.each do |name| 
      kpi_hash = self.cooldown_abilities[name][:kpi_hash] rescue {}
      @cooldowns[name] = {active: true, temp: true, buffer: 0, cp: CooldownParse.new(fight_parse_id: self.id, cd_type: 'cd', name: name, kpi_hash: kpi_hash, started_at: self.started_at)}
    end
    @debuffs = {}
    @debuff_uptimes = {}
    self.debuff_abilities.each do |name, hash| 
      @uptimes[name] = {active: false, uptime: 0}
      @debuff_uptimes[name] = []
      @debuffs[name] = {}
    end
    @buffs = {}
    @buff_uptimes = []
    self.buff_abilities.each do |name, hash| 
      @uptimes[name] = {active: false, uptime: 0}
      @buffs[name] = {active: false, temp: true}
    end
    @external_buffs = {}
    @external_buff_uptimes = {}
    self.external_buff_abilities.each do |name, hash| 
      @uptimes[name] = {active: false, uptime: 0}
      @external_buff_uptimes[name] = []
      @external_buffs[name] = {}
    end
    self.track_casts.each do |spell, hash|
      self.casts_hash[spell] = []
      self.casts_hash["#{spell}_waste"] = {waste: 0, off_cd: true} if hash.has_key?(:buff)
    end
    self.talents = self.combatant_info['talents'].map{|hash| hash['id']}.join('.') rescue nil
    self.fight_length = self.fight_time
    @pets = {}
    @kpis = {}
    @casts = {}
    @pet_kpis = {}
    @actors = {}
    @player_ids = []
    @kpi_parses = {}
    @next_cast_possible = nil
    @begin_cast_name = nil
    @begin_cast_time = 0
    @check_abc = false
    @abc_wasted = 0
    @casts_details = []
    @resources = {}
    @energize = {}
    @dying = false
    @dead = false
    @cds = {}
    @pandemic = {}
    self.version = self.class.latest_version
    self.hotfix = self.class.latest_hotfix
    self.save

    create_kpi_parses
  end

  def init_pets(pets)
    #override
  end

  # settings

  def self.score_categories
    return {
      'casts_score' => 'Casts',
    }
  end

  def self.percent_label(mine, theirs)
    return "N/A" if mine == 0 || theirs == 0
    percent = 100 * (theirs - mine) / mine
    color = percent > 15 ? 'green' : percent < -15 ? 'red' : ''
    return "<span class='#{color}'>#{percent}% #{mine == theirs ? '➡' : theirs > mine ? '⬆' : '⬇'}</span>"
  end

  def spell_name(id)
    return {
      1 => 'Melee',
      188017 => 'Ancient Mana Potion',
      188030 => 'Leytorrent Potion',
      188027 => 'Potion of Deadly Grace',
      188028 => 'Potion of the Old War',
      188029 => 'Unbending Potion',
      229206 => 'Potion of Prolonged Power',
      190909 => 'Mark of the Claw',
      228399 => 'Mark of the Heavy Hide',
      191080 => 'Mark of the Hidden Satyr',
      2825 => 'Bloodlust',
      32182 => 'Heroism',
      80353 => 'Time Warp',
      221803 => 'Infested Ground',
      222166 => 'Horrific Appendages',
      222517 => 'Cleansed Ancient\'s Blessing',
      222519 => 'Cleansed Sister\'s Blessing',
      222518 => 'Cleansed Wisp\'s Blessing',
      221796 => 'Blood Frenzy',
      221770 => 'Rend Flesh',
      221878 => 'Spirit Fragment',
      221837 => 'Solitude',
      221992 => 'Cleansing Wisp',
      221752 => 'Heightened Senses',
      222191 => 'Volatile Ichor',
      221812 => 'Plague Swarm',
      221857 => 'Tormenting Cyclone',
      222050 => 'Maddening Whispers',
      222706 => 'Poisoned Dreams',
      222479 => 'Shadowy Reflection',
      222481 => 'Shadowy Reflection',
      222025 => 'Nightmarish Ichor',
      222207 => 'Darkening Soul',
      221695 => 'Wild God\'s Fury',
      215405 => 'Rancid Maw',
      214622 => 'Warlord\'s Fortitude',
      215631 => 'Focused Lightning',
      214971 => 'Gaseous Bubble',
      215715 => 'Spawn of Serpentrix',
      215296 => 'Raging Storm',
      215293 => 'Raging Storm',
      215859 => 'Volatile Magic',
      214571 => 'Nightwell Energy',
      214577 => 'Nightwell Energy',
      215058 => 'Shadow Wave',
      214128 => 'Acceleration',
      216085 => 'Mechanical Bomb Squirrel',
      215197 => 'Phased Webbing',
      214831 => 'Chaotic Energy',
      215602 => 'Vampyr\'s Kiss',
      224346 => 'Solemnity',
      215815 => 'Burning Intensity',
      214423 => 'Stance of the Mountain',
      215263 => 'Pulse',
      214962 => 'Sheathed in Frost',
      215936 => 'Soul Sap',
      215938 => 'Soul Sap',
      215658 => 'Darkstrikes',
      215659 => 'Darkstrikes',
      214054 => 'Fel Meteor',
      214048 => 'Fel Meteor',
      215956 => 'Valarjar\'s Path',
      214798 => 'Screams of the Dead',
      215247 => 'Shroud of the Naglfar',
      215248 => 'Shroud of the Naglfar',
      214198 => 'Expel Light',
      214200 => 'Expel Light',
      214203 => 'Spear of Light',
      214140 => 'Nether Anti-Toxin',
      214142 => 'Nether Anti-Toxin',
      215266 => 'Fragile Echo',
      214168 => 'Brutal Haymaker',
      214169 => 'Brutal Haymaker',
      228784 => 'Brutal Haymaker',
      215444 => 'Dark Blast',
      213887 => 'Scent of Blood',
      213888 => 'Scent of Blood',
      214449 => 'Choking Flames',
      214459 => 'Choking Flames',
      213782 => 'Nightfall',
      213784 => 'Nightfall',
      214249 => 'Nightmare Essence',
      214350 => 'Nightmare Essence',
      214340 => 'Down Draft',
      215024 => 'Down Draft',
      214224 => 'Feed on the Weak',
      214229 => 'Feed on the Weak',
      215670 => 'Taint of the Sea',
      215672 => 'Taint of the Sea',
      214366 => 'Crystalline Body',
      214980 => 'Slicing Maelstrom',
      214985 => 'Slicing Maelstrom',
    }[id]
  end

  def channel_abilities
    return []
  end

  def ignore_casts
    return []
  end

  def track_casts
    return {}
  end

  # keep track of spell ticks that we don't want to track
  def ticks
    return {}
  end

  def pet_name(id)
    return nil
  end

  # track uptimes of abilities
  def uptime_abilities
    return {}
  end

  # track uptimes of buffs
  def buff_abilities
    return {}
  end

  # track uptimes of cooldowns
  def cooldown_abilities
    return {}
  end

  # track uptimes of debuffs
  def debuff_abilities
    return {}
  end

  # track uptimes of external buffs
  def external_buff_abilities
    return {}
  end

  # track uptimes of external cooldowns
  def external_cooldown_abilities
    return {}
  end

  # track damage done while abilities are active. uses kpi_hash[:damage_done]
  def dps_buff_abilities
    return {

    }
  end

  # track damage done directly by abilities
  # piggyback: add extra damage to an existing CooldownParse, instead of creating a new one
  # single: create a CooldownParse and close it right away, to record a single attack
  def dps_abilities
    return {
      # 'Divine Judgment' => {single: true},
    }
  end

  def potions
    return [
      'Ancient Mana Potion',
      'Leytorrent Potion',
      'Potion of Deadly Grace',
      'Potion of the Old War',
      'Unbending Potion',
      'Potion of Prolonged Power',
    ]
  end

  def procs
    return {
      'Bloodlust' => {},
      'Heroism' => {},
      'Time Warp' => {},
      'Ancient Hysteria' => {},
      'Spirit Shift' => {},
      'Sign of the Dark Star' => {},
      'Sudden Intuition' => {},
      'Hungering Blows' => {},
      'Anzu\'s Flight' => {},
      'Archmage\'s Incandescence' => {},
      'Archmage\'s Greater Incandescence' => {},
      'Demonbane' => {},
      'Voidsight' => {},
      'Bulwark of Purity' => {},
      'Mark of the Claw' => {},
      'Mark of the Heavy Hide' => {},
      'Mark of the Hidden Satyr' => {},
      'Infested Ground' => {cd: 60},
      'Horrific Appendages' => {},
      'Cleansed Ancient\'s Blessing' => {},
      'Cleansed Sister\'s Blessing' => {},
      'Cleansed Wisp\'s Blessing' => {},
      'Blood Frenzy' => {},
      'Rend Flesh' => {},
      'Spirit Fragment' => {},
      'Solitude' => {cd: 120},
      'Cleansing Wisp' => {cd: 60},
      'Heightened Senses' => {},
      'Volatile Ichor' => {},
      'Plague Swarm' => {},
      'Tormenting Cyclone' => {},
      'Maddening Whispers' => {cd: 120},
      'Poisoned Dreams' => {},
      'Shadowy Reflection' => {},
      'Nightmarish Ichor' => {},
      'Darkening Soul' => {},
      'Wild God\'s Fury' => {cd: 120},
      'Rancid Maw' => {},
      'Warlord\'s Fortitude' => {},
      'Focused Lightning' => {},
      'Gaseous Bubble' => {cd: 60},
      'Spawn of Serpentrix' => {},
      'Raging Storm' => {},
      'Volatile Magic' => {},
      'Nightwell Energy' => {},
      'Shadow Wave' => {},
      'Acceleration' => {},
      'Mechanical Bomb Squirrel' => {},
      'Phased Webbing' => {},
      'Chaotic Energy' => {},
      'Vampyr\'s Kiss' => {cd: 20, extra: 2},
      'Solemnity' => {},
      'Burning Intensity' => {},
      'Stance of the Mountain' => {cd: 60},
      'Pulse' => {},
      'Sheathed in Frost' => {cd: 120},
      'Soul Sap' => {},
      'Darkstrikes' => {cd: 75},
      'Fel Meteor' => {},
      'Valarjar\'s Path' => {cd: 120},
      'Screams of the Dead' => {},
      'Shroud of the Naglfar' => {},
      'Expel Night' => {cd: 90},
      'Spear of Light' => {cd: 60},
      'Nether Anti-Toxin' => {},
      'Fragile Echo' => {},
      'Brutal Haymaker' => {},
      'Dark Blast' => {},
      'Scent of Blood' => {},
      'Choking Flames' => {},
      'Nightfall' => {},
      'Nightmare Essence' => {},
      'Down Draft' => {},
      'Feed on the Weak' => {},
      'Taint of the Sea' => {cd: 120},
      'Crystalline Body' => {cd: 120},
      'Slicing Maelstrom' => {cd: 120},
    }
  end

  def self.latest_version
    return 3
  end

  def self.latest_hotfix
    return 2
  end

  def self.latest_patch
    return nil
  end

  def in_progress?
    return false
  end

  def graph_series
    return {}
  end

  def set_bonus(tier)
    return self.combatant_info['gear'].reject{|item| !self.class::SET_IDS[tier].include?(item['id'])}.count rescue 0
  end

  # getters

  def fight
    return Fight.find_by(report_id: self.report_id, fight_id: self.fight_id)
  end

  def fight_date
    return self.report_started_at.nil? ? "N/A" : self.report_started_at.strftime("%-m/%-d")
  end

  def fight_time
    return (self.ended_at - self.started_at) / 1000 rescue 0
  end

  def fight_time_s
    return "(#{self.fight_time / 60}:#{"%02d" % (self.fight_time % 60)})"
  end

  def event_time(timestamp, round=false, started_at=self.started_at)
    return '' if timestamp.nil?
    string = "#{((timestamp - started_at) / 1000) / 60}:#{"%02d" % (((timestamp - started_at) / 1000) % 60)}"
    string += "." + "#{(timestamp - started_at) % 1000}".rjust(3, "0") unless round
    return string
  end

  def dps
    return (self.kpi_hash[:player_damage_done].to_i + self.kpi_hash[:pet_damage_done].to_i) / self.fight_time rescue 0
  end

  def buff_upratio(key)
    return [(0.1 * self.resources_hash["#{key}_uptime".to_sym] / self.fight_time).round(2), 100].min rescue 0
  end

  def buff_upratio_s(key)
    return "#{self.resources_hash["#{key}_uptime".to_sym].to_i / 1000}s / #{self.fight_time}s"
  end

  def debuff_upratio(key)
    return 0 if self.resources_hash["#{key}_uptime".to_sym].to_i == 0
    if self.resources_hash["#{key}_downtime".to_sym].to_i == 0
      return [(0.1 * self.resources_hash["#{key}_uptime".to_sym] / self.fight_time).round(2), 100].min rescue 0
    else
      return (100.0 * self.resources_hash["#{key}_uptime".to_sym] / (self.resources_hash["#{key}_uptime".to_sym] + self.resources_hash["#{key}_downtime".to_sym])).round(2) rescue 0
    end
  end

  def debuff_upratio_s(key)
    if self.resources_hash["#{key}_downtime".to_sym].to_i == 0
      return "#{self.resources_hash["#{key}_uptime".to_sym].to_i / 1000}s / #{self.fight_time}s"
    else
      return "#{self.resources_hash["#{key}_uptime".to_sym].to_i / 1000}s / #{(self.resources_hash["#{key}_uptime".to_sym].to_i + self.resources_hash["#{key}_downtime".to_sym].to_i) / 1000}s"
    end
  end

  def max_basic_bar
    return self.dps
  end

  def max_cooldown
    return self.cooldowns_hash.values.map{|i| i.to_i}.max
  end

  def spec
    return self['spec'] || ''
  end

  def effective_cd(hash)
    fight_time = self.fight_time - (self.kpi_hash[:dead_time].to_i / 1000)
    return fight_time / casts_possible(hash) rescue 0
  end

  def casts_possible(hash)
    fight_time = self.fight_time - (self.kpi_hash[:dead_time].to_i / 1000)
    return hash[:max] if hash.has_key?(:max)
    return nil if hash[:cd].nil?
    if hash.has_key?(:buff)
      wasted = self.casts_hash["#{hash[:name]}_waste"][:waste].to_i / 1000 rescue 0
      wasted_casts = wasted / hash[:cd].to_i rescue 0
      return (self.casts_hash["#{hash[:name]}"].count rescue 0) + wasted_casts
    end
    if hash[:cd] > 60
      hash[:leeway] ||= 10
    else
      hash[:leeway] ||= 5
    end
    return (1.0 + (fight_time - hash[:leeway] + hash[:reduction].to_i).floor / hash[:cd] + hash[:extra].to_i).to_i
  end

  def cooldown_timeline_bars
    bars = {'potion' => {}, 'proc' => {}, 'pet' => {}, 'cd' => {}, 'external' => {}, 'external_absorb' => {}}
    self.procs.each do |name, proc|
      bars['proc'][name] = {cd: proc[:cd], optional: true, color: 'green'}
    end
    self.potions.each do |name, potion|
      bars['potion'][name] = {cd: nil, optional: true, max: 2, color: 'blue'}
    end
    self.cooldown_parses.where(cd_type: 'pet').each do |pet|
      bars['pet'][pet.name] = {color: 'orange'}
    end
    bars['pet'].delete('Unknown')
    return bars
  end

  def casts_rows
    return self.casts_hash.map{|name, casts| [name, casts]}.sort{|a, b| b[1].size <=> a[1].size}
  end

  def kill_label
    return "#{self.kill? ? 'Kill' : "#{self.boss_percent / 100}% Wipe"} (#{Time.at(self.fight_time).strftime("%M:%S")})"
  end

  def death_event_s(event)
    if event[:type] == 'damage'
      "#{event[:source]}'s #{event[:name]} deals <span class='red'>#{event[:amount]}</span> damage (<span class='red'>#{event[:hp]}% HP</span>)"
    elsif event[:type] == 'heal'
      "#{event[:source]}'s #{event[:name]} heals for <span class='green'>#{event[:amount]}</span> (<span class='green'>#{event[:hp]}% HP</span>)"
    elsif event[:type] == 'absorb'
      "#{event[:source]}'s #{event[:name]} absorbs <span class='green'>#{event[:amount]}</span> damage (<span class='green'>#{event[:hp]}% HP</span>)"
    elsif event[:type] == 'death'
      "Death (<span class='red'>#{event[:overkill].to_i}</span> overkill)"
    end
  end

  def crit_scaling
    return 400
  end

  def haste_scaling
    return 375
  end

  def mastery_scaling
    return 400
  end

  def crit_percent
    crit = [self.combatant_info['critMelee'].to_i, self.combatant_info['critRanged'].to_i, self.combatant_info['critSpell'].to_i].max
    return 16 + (1.0 * crit / self.crit_scaling)
  end

  def haste_reduction_percent
    haste = [self.combatant_info['hasteMelee'].to_i, self.combatant_info['hasteRanged'].to_i, self.combatant_info['hasteSpell'].to_i].max
    return 1.0 * haste / self.haste_scaling
  end

  def haste_reduction_ratio
    return 1 / (1 + self.haste_reduction_percent / 100)
  end

  def mastery_percent
    mastery = self.combatant_info['mastery'].to_i
    return 1.0 * mastery / self.mastery_scaling
  end

  def mastery_ratio
    
  end

  def gcd
    return [1500 * self.haste_reduction_ratio, 750].max
  end

  def track_resources
    return []
  end

  def show_resources
    return self.track_resources
  end

  def talent(row)
    return spell_name(self.combatant_info['talents'][row]['id']) rescue nil
  end

  def artifact(ability_name)
    return self.combatant_info['artifact'].select{|trait| spell_name(trait['spellID']) == ability_name}.first['rank'] rescue 0
  end

  # event handlers

  def handle_my_event(event) # things done by you
    check_cds(event)
    case event['type']
    when 'begincast'
      begin_cast_event(event)
    when 'cast'
      cast_event(event)
    when 'energize'
      energize_event(event)
    when 'applybuff'
      if event['sourceID'] == event['targetID']
        gain_self_buff_event(event) 
      else
        apply_external_buff_event(event) 
      end
    when 'refreshbuff'
      if event['sourceID'] == event['targetID']
        refresh_self_buff_event(event)
      else
        drop_external_buff_event(event, true) 
        apply_external_buff_event(event)
      end
    when 'applybuffstack'
      if event['sourceID'] == event['targetID']
        gain_self_buff_stack_event(event) 
      else
        apply_external_buff_stack_event(event)
      end
    when 'removebuff'
      if event['sourceID'] == event['targetID']
        lose_self_buff_event(event) 
      else
        drop_external_buff_event(event) 
      end
    when 'removebuffstack'
      if event['sourceID'] == event['targetID']
        lose_self_buff_stack_event(event) 
      else
        drop_external_buff_stack_event(event) 
      end
    when 'applydebuff'
      apply_debuff_event(event)
    when 'applydebuffstack'
      apply_debuff_stack_event(event)
    when 'refreshdebuff'
      refresh_debuff_event(event)
    when 'removedebuff'
      remove_debuff_event(event)
    when 'removedebuffstack'
      remove_debuff_stack_event(event)
    when 'absorbed'
      absorb_event(event)
    when 'heal'
      heal_event(event)
    when 'damage'
      deal_damage_event(event)
    when 'summon'
      summon_pet_event(event)
    else return
    end
  end

  def handle_receive_event(event) # things done to you
    case event['type']
    when 'applybuff'
      gain_external_buff_event(event)
    when 'refreshbuff'
      lose_external_buff_event(event, true)
      gain_external_buff_event(event)
    when 'removebuff'
      lose_external_buff_event(event)
    when 'absorbed'
      receive_absorb_event(event)
    when 'heal'
      receive_heal_event(event)
    when 'damage'
      receive_damage_event(event)
    else 
      return 
    end
  end

  def handle_pet_event(event) # things done by your pet
    case event['type']
    when 'damage'
      pet_damage_event(event)
    when 'removedebuff'
      pet_remove_debuff_event(event)
    when 'energize'
      energize_event(event) if event['targetID'] == self.actor_id
    when 'heal'
      pet_heal_event(event)
    end
    if @pets.has_key?(event['sourceID']) && !@pets[event['sourceID']][:pet].nil?
      @pets[event['sourceID']][:pet].ended_at = event['timestamp']
    end
  end

  def handle_receive_pet_event(event) # things done to your pet
    case event['type']
    when 'death'
      pet_death_event(event)
    end
  end

  def handle_external_event(event) # mostly used for tracking healers' damage reduction
    # overwrite
  end

  def check_cds(event)
    off_cd = @cds.map{|k,v| k if event['timestamp'].to_i > v.to_i}.compact
    off_cd.each do |name|
      if self.track_casts[name].has_key?(:buff)
        self.casts_hash["#{name}_waste"] ||= {waste: 0}
        self.casts_hash["#{name}_waste"][:off_cd] = true
        
        if @cooldowns[self.track_casts[name][:buff]][:active]
          self.casts_hash["#{name}_waste"][:waste] -= event['timestamp']
        end
      end
      save_cast_detail(event, name, 'off_cd', nil, event['timestamp'])
      @cds.delete(name)
    end
  end

  def check_gcd(name, timestamp)
    return unless @check_abc
    return if @next_cast_possible.nil? || name == 'Melee'
    if !@begin_cast_name.nil? 
      # this should mean the cast was cancelled
      # wasted time is time spent casting the cancelled spell (current time - cast started)
      self.resources_hash[:abc_fails] ||= []
      self.resources_hash[:abc_fails] << {timestamp: @begin_cast_time, name: @begin_cast_name, wasted: timestamp - @begin_cast_time, cancelled: true}
    else
      # compare this time to when the next cast should have been possible
      wasted = ((timestamp - @next_cast_possible) * 0.001).round(1)
      @abc_wasted += wasted if wasted >= 0.1
      if wasted > 1
        self.resources_hash[:abc_fails] ||= []
        self.resources_hash[:abc_fails] << {timestamp: timestamp, name: name, wasted: wasted}
      end
    end
  end

  def save_cast_detail(event, ability_name, type, msg=nil, timestamp=nil)
    return if ability_name == 'Melee'
    timestamp ||= event['timestamp']
    # avoid duplicate records
    # return if @casts_details.size > 0 && @casts_details.last['timestamp'] == timestamp && @casts_details.last['type'] == type && @casts_details.last['ability'] == ability_name

    cast_detail = {'timestamp' => timestamp, 'ability' => ability_name, 'type' => type}
    @resources.each{|k, v| cast_detail[k] = v }
    (event['classResources'] || []).each do |resource|
      cast_detail["r#{resource['type']}"] = resource['amount']
      cast_detail["r#{resource['type']}_max"] = resource['max']
    end
    # energize events will precede cast events. we want to show the resource value before the energize
    if type == 'cast'
      if @energize.has_key?(ability_name)
        @energize[ability_name].each do |key, value|
          cast_detail[key] -= value
        end
        # @energize.delete(ability_name)
      end
      @energize = {}
    end
    cast_detail['msg'] = msg unless msg.nil?
    @casts_details << cast_detail
  end

  def begin_cast_event(event)
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    return false if ignore_casts.include?(ability_name)
    check_gcd(ability_name, event['timestamp'])
    save_cast_detail(event, ability_name, 'begin_cast')
    @next_cast_possible = (event['timestamp'] + self.gcd).to_i
    @begin_cast_name = ability_name
    @begin_cast_time = event['timestamp']
  end

  def cast_event(event)
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    return false if ignore_casts.include?(ability_name)
    save_cast_detail(event, ability_name, 'cast') if self.ticks[event['ability']['guid']].nil? && !event['tick']

    # update how many resources we have after the cast
    (event['classResources'] || []).each do |resource|
      if self.track_resources.include?(resource['type'])
        @resources["r#{resource['type']}"] = resource['amount'].to_i - resource['cost'].to_i
        @resources["r#{resource['type']}_max"] = resource['max'].to_i
      end
    end

    # see if this is the end of the cast that was started earlier
    if @begin_cast_name != ability_name
      check_gcd(ability_name, event['timestamp'])
      @next_cast_possible = (event['timestamp'] + self.gcd).to_i
    elsif @begin_cast_name.nil? || event['timestamp'] > @next_cast_possible
      @next_cast_possible = event['timestamp']
    end
    @begin_cast_name = nil
    @begin_cast_time = nil

    ability_name = spell_name(event['ability']['guid'])
    return if ability_name.nil?
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"

    if self.track_casts.include?(ability_name) && self.ticks[event['ability']['guid']].nil?
      self.casts_hash[ability_name] << event['timestamp']
      @cds[ability_name] = (event['timestamp'] + self.track_casts[ability_name][:cd] * 1000).to_i unless self.track_casts[ability_name][:cd].nil?
      if self.casts_hash.has_key?("#{ability_name}_waste") && self.casts_hash["#{ability_name}_waste"][:off_cd]
        self.casts_hash["#{ability_name}_waste"][:off_cd] = false
        self.casts_hash["#{ability_name}_waste"][:waste] += event['timestamp']
      end
    end
    @casts["#{ability_name}_#{target_key}"] ||= [nil]
    @casts["#{ability_name}_#{target_key}"] << {timestamp: event['timestamp'], cps: {}}
    
    # check if cooldowns are active, or need to drop
    @cooldowns.each do |name, hash|
      @casts["#{ability_name}_#{target_key}"].last[:cps][name] = hash[:cp].id if hash[:active]
      drop_cooldown(name, event['timestamp']) if hash[:buffer] != 0
    end
    if self.dps_abilities.has_key?(ability_name) && !self.dps_abilities[ability_name][:channel] && !self.dps_abilities[ability_name].has_key?(:piggyback)
      unless self.procs.has_key?(ability_name)
        return if !@cooldowns[ability_name][:cp].nil? && event['timestamp'] - @cooldowns[ability_name][:cp].started_at < 500
        if !@cooldowns[ability_name][:cp].nil? && @cooldowns[ability_name][:active] && !@cooldowns[ability_name][:temp]
          ended_at = @cooldowns[ability_name][:cp].ended_at || event['timestamp']
          drop_cooldown(ability_name, ended_at, nil, true)
        end
        kpi_hash = self.cooldown_abilities[ability_name][:kpi_hash] rescue {damage_done: 0}
        gain_cooldown(ability_name, event['timestamp'], kpi_hash)
        @cooldowns[ability_name][:cp].ended_at = event['timestamp']
      end
    end

    # check if combat res
    if @dead
      @dead = false
      self.kpi_hash[:dead_time] = self.kpi_hash[:dead_time].to_i + event['timestamp']
    end
  end

  def energize_event(event)
    # update how many resources we have after the cast
    if self.track_resources.include?(event['resourceChangeType'])
      before = @resources["r#{event['resourceChangeType']}"].to_i
      @resources["r#{event['resourceChangeType']}"] = [@resources["r#{event['resourceChangeType']}"].to_i + event['resourceChange'].to_i, @resources["r#{event['resourceChangeType']}_max"].to_i].min
      @energize[event['ability']['name']] ||= {}
      @energize[event['ability']['name']]["r#{event['resourceChangeType']}"] = @resources["r#{event['resourceChangeType']}"] - before # ignore waste
    end
  end

  def check_resource_cap(resource_amount, max_resource_amount, timestamp, resource_type = nil)
    if resource_amount >= max_resource_amount # capped
      @capped_started_at = timestamp unless @capped # ignore if already capped
      @capped = true
    elsif @capped # not capped but was
      key = (resource_type.nil? ? :capped_time : "#{resource_type}_capped_time".to_sym)
      self.resources_hash[key] += timestamp - @capped_started_at # record how long we were capped
      @capped = false
      end
  end

  def refresh_self_buff_event(event)
    lose_self_buff_event(event, true) 
    gain_self_buff_event(event, true)
  end

  def gain_self_buff_event(event, refresh=false)
    ability_name = spell_name(event['ability']['guid'])
    return if ability_name.nil?
    if self.uptime_abilities.keys.include? ability_name
      gain_uptime(ability_name, event['timestamp'])
    end
    if self.cooldown_abilities.keys.include? ability_name
      unless self.cooldown_abilities[ability_name][:ignore_buff]
        gain_cooldown(ability_name, event['timestamp'], self.cooldown_abilities[ability_name][:kpi_hash])
      end
    end
    if self.potions.include? ability_name
      gain_cooldown(ability_name, event['timestamp'], {}, 'potion')
    end
    if self.procs.keys.include? ability_name
      gain_cooldown(ability_name, event['timestamp'], {}, 'proc')
    end
    if self.buff_abilities.keys.include? ability_name
      apply_buff(ability_name, event['timestamp'], self.buff_abilities[ability_name])
      if @buff_uptimes.include?(ability_name) && !@uptimes[ability_name][:active]
        gain_uptime(ability_name, event['timestamp'])
      end
    end
    if self.external_buff_abilities.keys.include? ability_name
      event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
      apply_external_buff(ability_name, target_id, event['targetInstance'], event['timestamp'], self.external_buff_abilities[ability_name])
    end
  end

  def gain_self_buff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    if self.buff_abilities.keys.include? ability_name
      apply_buff_stack(ability_name, event['stack'], event['timestamp'])
      if @buff_uptimes.include?(ability_name) && !@uptimes[ability_name][:active]
        gain_uptime(ability_name, event['timestamp'])
      end
    end
    if self.external_buff_abilities.keys.include? ability_name
      event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
      apply_external_buff_stack(ability_name, target_id, event['targetInstance'], event['stack'], event['timestamp'])
    end
  end

  def lose_self_buff_event(event, force=true)
    ability_name = spell_name(event['ability']['guid'])
    return if ability_name.nil?
    if self.uptime_abilities.keys.include? ability_name
      drop_uptime(ability_name, event['timestamp'])
    end
    if self.cooldown_abilities.keys.include? ability_name
      unless self.cooldown_abilities[ability_name][:ignore_buff]
        drop_cooldown(ability_name, event['timestamp'], nil, force)
      end
    end
    if self.potions.include? ability_name
      drop_cooldown(ability_name, event['timestamp'], 'potion', force)
    end
    if self.procs.keys.include? ability_name
      drop_cooldown(ability_name, event['timestamp'], 'proc', force)
    end
    if self.buff_abilities.keys.include? ability_name
      remove_buff(ability_name, event['timestamp'])
      if !@buff_uptimes.include?(ability_name) && @uptimes[ability_name][:active]
        drop_uptime(ability_name, event['timestamp'])
      end
    end
    if self.external_buff_abilities.keys.include? ability_name
      event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
      remove_external_buff(ability_name, target_id, event['targetInstance'], event['timestamp'])
    end
  end

  def lose_self_buff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    if self.buff_abilities.keys.include? ability_name
      remove_buff_stack(ability_name, event['stack'], event['timestamp'])
      if !@buff_uptimes.include?(ability_name) && @uptimes[ability_name][:active]
        drop_uptime(ability_name, event['timestamp'])
      end
    end
    if self.external_buff_abilities.keys.include? ability_name
      event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
      remove_external_buff_stack(ability_name, target_id, event['targetInstance'], event['stack'], event['timestamp'])
    end
  end

  def apply_external_buff_event(event)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.external_buff_abilities.keys.include? ability_name
      apply_external_buff(ability_name, target_id, event['targetInstance'], event['timestamp'], self.external_buff_abilities[ability_name])
    end
  end

  def apply_external_buff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.external_buff_abilities.keys.include? ability_name
      apply_external_buff_stack(ability_name, target_id, event['targetInstance'], event['stack'], event['timestamp'])
    end
  end

  def drop_external_buff_event(event, refresh=false, force=true)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.external_buff_abilities.keys.include? ability_name
      remove_external_buff(ability_name, target_id, event['targetInstance'], event['timestamp'])
    end
  end

  def drop_external_buff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.external_buff_abilities.keys.include? ability_name
      remove_external_buff_stack(ability_name, target_id, event['targetInstance'], event['stack'], event['timestamp'])
    end
  end

  def refresh_debuff_event(event)
    remove_debuff_event(event, true) 
    apply_debuff_event(event, true)
  end

  def apply_debuff_event(event, refresh=false)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.debuff_abilities.keys.include? ability_name
      apply_debuff(ability_name, target_id, event['targetInstance'], event['targetIsFriendly'], event['timestamp'], self.debuff_abilities[ability_name])
      if @debuff_uptimes[ability_name].count > 0 && !@uptimes[ability_name][:active]
        gain_uptime(ability_name, event['timestamp'])
      end
    end
  end

  def apply_debuff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.debuff_abilities.keys.include? ability_name
      apply_debuff_stack(ability_name, target_id, event['targetInstance'], event['targetIsFriendly'], event['stack'], event['timestamp'])
      if @debuff_uptimes[ability_name].count > 0 && !@uptimes[ability_name][:active]
        gain_uptime(ability_name, event['timestamp'])
      end
    end
  end

  def remove_debuff_event(event, refresh=false)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    return if ability_name.nil?
    if self.debuff_abilities.keys.include? ability_name
      # check for pandemic
      if refresh && !(@debuffs[ability_name][target_key][:dp].kpi_hash[:estimated_end] rescue nil).nil?
        @pandemic[ability_name] ||= {}
        @pandemic[ability_name][target_key] = [@debuffs[ability_name][target_key][:dp].kpi_hash[:estimated_end].to_i - event['timestamp'], 0].max
      end
      remove_debuff(ability_name, target_id, event['targetInstance'], event['targetIsFriendly'], event['timestamp'])
      if @debuff_uptimes[ability_name].count == 0 && @uptimes[ability_name][:active]
        drop_uptime(ability_name, event['timestamp'])
      end
    end
  end

  def remove_debuff_stack_event(event)
    ability_name = spell_name(event['ability']['guid'])
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    return if ability_name.nil?
    if self.debuff_abilities.keys.include? ability_name
      remove_debuff_stack(ability_name, target_id, event['targetInstance'], event['targetIsFriendly'], event['stack'], event['timestamp'])
    end
  end

  def deal_damage_event(event)
    return if event['targetIsFriendly']
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    self.kpi_hash[:player_damage_done] += event['amount']
    @kpi_parses[:dps].kpi_hash[:player_damage_done] += event['amount']
    kpi_key = "#{event['sourceID']}-#{event['ability']['name']}"
    @kpi_parses[:dps].details_hash[kpi_key] ||= {name: event['ability']['name'], damage: 0, hits: 0}
    @kpi_parses[:dps].details_hash[kpi_key][:damage] += event['amount']
    @kpi_parses[:dps].details_hash[kpi_key][:hits] += 1

    # this is ugly, but it'll have to do for now
    if @cooldowns.has_key?('Spirit Shift') && @cooldowns['Spirit Shift'][:active]
      amount = event['amount'] + event['absorbed']
    else
      amount = event['amount']
    end

    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}"
    if !@casts["#{ability_name}_#{target_key}"].nil?
      @casts["#{ability_name}_#{target_key}"].shift
    elsif self.casts_hash[ability_name].blank?
      # probably a pre-cast spell
      save_cast_detail({}, ability_name, 'cast', nil, self.started_at)
      @casts["#{ability_name}_#{target_key}"] ||= [nil]
      @casts["#{ability_name}_#{target_key}"] << {timestamp: event['timestamp'], cps: {}}
      if self.track_casts.include?(ability_name) && self.ticks[event['ability']['guid']].nil?
        self.casts_hash[ability_name] << event['timestamp']
        @cds[ability_name] = (event['timestamp'] + self.track_casts[ability_name][:cd] * 1000).to_i unless self.track_casts[ability_name][:cd].nil?
      end
    end
    cast_time = @casts["#{ability_name}_#{target_key}"].first[:timestamp] rescue nil
    cast_cps = @casts["#{ability_name}_#{target_key}"].first[:cps] rescue {}
    cast_time ||= event['timestamp']
    if self.channel_abilities.include?(ability_name)
      # manually mark up casting time, to do channeled casts properly for ABC checking
      @next_cast_possible = (event['timestamp'] + self.gcd).to_i
    end
    self.dps_abilities.each do |name, hash|
      if ability_name == name
        if hash[:piggyback] # add this info to an existing cooldown parse
          unless @cooldowns[hash[:piggyback]][:cp].nil?
            if !cast_cps.has_key?(hash[:piggyback])
              # No key existing either means it wasn't active, or we didn't record the cast event
              # if we didn't record the cast event, we should still evaluate the piggyback
              cp = @cooldowns[hash[:piggyback]][:cp] if cast_time == event['timestamp']
            else
              if cast_cps[hash[:piggyback]] == @cooldowns[hash[:piggyback]][:cp].id
                cp = @cooldowns[hash[:piggyback]][:cp]
              else
                cp = self.cooldown_parses.find(cast_cps[hash[:piggyback]]) rescue nil
              end
            end
            next if cp.nil? # we could be looking for a temp that is already gone
            if self.ticks.has_key?(event['ability']['guid'])
              # group this as primary damage, since it's just a channel tick
              cp.kpi_hash[:damage_done] = cp.kpi_hash[:damage_done].to_i + amount
              cp.details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
              cp.details_hash[target_key][:damage] += amount
              cp.details_hash[target_key][:hits] += 1
              cp.ended_at = event['timestamp']
              cp.save if !@cooldowns[name][:active] && !@cooldowns[name][:temp]
              @cooldowns[name][:temp] = false
            else
              cp.kpi_hash[:extra_damage] = cp.kpi_hash[:extra_damage].to_i + amount
              cp.details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0, extra_damage: 0, extra_hits: 0}
              cp.details_hash[target_key][:extra_damage] = cp.details_hash[target_key][:extra_damage].to_i + amount
              cp.details_hash[target_key][:extra_hits] = cp.details_hash[target_key][:extra_hits].to_i + 1
            end

            if !cast_cps.has_key?(hash[:piggyback])
              cp.save if !@cooldowns[hash[:piggyback]][:active] && !@cooldowns[hash[:piggyback]][:temp]
            else
              if cast_cps[hash[:piggyback]] == @cooldowns[hash[:piggyback]][:cp].id
                cp.save if !@cooldowns[hash[:piggyback]][:active] && !@cooldowns[hash[:piggyback]][:temp]
              else
                cp.save
              end
            end
          end
        else
          if hash[:single] # a one-off attack that we still want to track
            kpi_hash = self.cooldown_abilities[name][:kpi_hash] rescue {damage_done: 0}
            gain_cooldown(name, event['timestamp'], kpi_hash)
          end
          if @cooldowns[name][:cp].nil? 
            # probably cast before the fight started
            gain_cooldown(name, self.started_at, self.cooldown_abilities[name][:kpi_hash])
          end

          @cooldowns[name][:cp].kpi_hash[:damage_done] = @cooldowns[name][:cp].kpi_hash[:damage_done].to_i + amount
          @cooldowns[name][:cp].details_hash[target_key] ||= {name: @actors[target_id], damage: 0, hits: 0}
          @cooldowns[name][:cp].details_hash[target_key][:damage] += amount
          @cooldowns[name][:cp].details_hash[target_key][:hits] += 1
          @cooldowns[name][:cp].ended_at = event['timestamp']
          @cooldowns[name][:cp].save if !@cooldowns[name][:active] && !@cooldowns[name][:temp]
          @cooldowns[name][:temp] = false
          if hash[:single]
            drop_cooldown(name, event['timestamp'] + 1, nil, true)
          end
        end
      end
    end
    self.dps_buff_abilities.each do |name, hash|
      next if hash.has_key?(:ignore) && hash[:ignore].include?(ability_name)
      if cast_cps.has_key?(name)
        if cast_cps[name] != @cooldowns[name][:cp].id
          cp = self.cooldown_parses.find(cast_cps[name]) rescue nil
        else
          cp = @cooldowns[name][:cp]
        end
      elsif is_active?(name, event['timestamp'])
        cp = @cooldowns[name][:cp]
      end
      next if cp.nil? # we could be looking for a temp that is already gone
      next if hash.has_key?(:spells) && !hash[:spells].include?(ability_name)
      if hash.has_key?(:percent)
        increased_amount = (amount * hash[:percent] / (1 + hash[:percent])).to_i
      else
        increased_amount = amount
      end
      cp.kpi_hash[:damage_done] = cp.kpi_hash[:damage_done].to_i + increased_amount
      cp.details_hash[event['ability']['guid']] ||= {name: ability_name, damage: 0, hits: 0}
      cp.details_hash[event['ability']['guid']][:damage] += increased_amount
      cp.details_hash[event['ability']['guid']][:hits] += 1
      if cast_cps.has_key?(name)
        if cast_cps[name] != @cooldowns[name][:cp].id
          cp.save
        elsif !@cooldowns[name][:active] && !@cooldowns[name][:temp]
          cp.save
        end
      elsif !@cooldowns[name][:active] && !@cooldowns[name][:temp]
        cp.save
      end
    end
    check_for_debuffs(target_id, event['targetInstance'], event['timestamp'])
  end

  def summon_pet_event(event)
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    pet_summon(target_id, event['timestamp'])
  end

  def pet_damage_event(event)
    return if event['targetIsFriendly']
    ability_name = spell_name(event['ability']['guid']) || event['ability']['name']
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    amount = event['amount'].to_i
    self.kpi_hash[:pet_damage_done] = self.kpi_hash[:pet_damage_done].to_i + amount
    @kpi_parses[:dps].kpi_hash[:pet_damage_done] += amount
    kpi_key = "#{event['sourceID']}-#{ability_name}"
    @kpi_parses[:dps].details_hash[kpi_key] ||= {name: ability_name, damage: 0, hits: 0}
    @kpi_parses[:dps].details_hash[kpi_key][:damage] += amount
    @kpi_parses[:dps].details_hash[kpi_key][:hits] += 1
    if !@pets.has_key?(event['sourceID'])
      # pet was probably summoned before the fight began
      pet_summon(event['sourceID'], self.started_at)
    end
    @pets[event['sourceID']][:pet].kpi_hash[:damage_done] += amount
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]] ||= {name: @actors[target_id], damage: 0, hits: 0}
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:damage] += amount
    @pets[event['sourceID']][:pet].details_hash[@actors[target_id]][:hits] += 1
    @pets[event['sourceID']][:pet].ended_at = event['timestamp']

    self.dps_abilities.each do |name, hash|
      if ability_name == name
        if @cooldowns[name][:cp].nil? 
          # probably cast before the fight started
          gain_cooldown(name, self.started_at, self.cooldown_abilities[name][:kpi_hash])
        end
        target_key = "#{target_id.to_i}-#{event['targetInstance'].to_i}-pet#{event['sourceID']}"
        @cooldowns[name][:cp].kpi_hash[:pet_damage_done] = @cooldowns[name][:cp].kpi_hash[:pet_damage_done].to_i + amount
        @cooldowns[name][:cp].details_hash[target_key] ||= {name: @actors[target_id], source: @pets[event['sourceID']][:pet].name, damage: 0, hits: 0}
        @cooldowns[name][:cp].details_hash[target_key][:damage] += amount
        @cooldowns[name][:cp].details_hash[target_key][:hits] += 1
        @cooldowns[name][:cp].ended_at = event['timestamp']
        @cooldowns[name][:cp].save if !@cooldowns[name][:active] && !@cooldowns[name][:temp]
        @cooldowns[name][:temp] = false
      end
    end
    self.dps_buff_abilities.each do |name, hash|
      cp = @cooldowns[name][:cp]
      next if cp.nil? # we could be looking for a temp that is already gone
      next if hash.has_key?(:spells) && !hash[:spells].include?(ability_name)
      if hash.has_key?(:percent)
          increased_amount = (amount * hash[:percent] / (1 + hash[:percent])).to_i
        else
          increased_amount = amount
        end
      cp.kpi_hash[:pet_damage_done] = cp.kpi_hash[:pet_damage_done].to_i + increased_amount
      key = "#{event['ability']['guid']}-pet#{event['sourceID']}"
      cp.details_hash[key] ||= {name: ability_name, source: @pets[event['sourceID']][:pet].name, damage: 0, hits: 0, pet: true}
      cp.details_hash[key][:damage] += increased_amount
      cp.details_hash[key][:hits] += 1
      cp.save if !@cooldowns[name][:active] && !@cooldowns[name][:temp]
    end
  end

  def pet_heal_event(event)
    if !@pets.has_key?(event['sourceID'])
      # pet was probably summoned before the fight began
      pet_summon(event['sourceID'], self.started_at)
    end
    @pets[event['sourceID']][:pet].ended_at = event['timestamp']
  end

  def pet_remove_debuff_event(event)
    # overwrite
  end

  def pet_death_event(event)
    event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
    pet_death(target_id, event['timestamp'])
  end

  def pet_summon(id, timestamp, name=nil, kpi_hash={damage_done: 0})
    return if id.nil?
    name ||= (@actors[id] || 'Unknown')
    @pets[id] ||= {active: false, pet: nil}
    if @pets[id][:active]
      ended_at = @pets[id][:pet].ended_at || timestamp
      pet_death(id, ended_at)
    end
    @pets[id][:active] = true
    @pets[id][:pet] = CooldownParse.new(fight_parse_id: self.id, cd_type: 'pet', name: name, kpi_hash: kpi_hash, started_at: timestamp)
  end

  def pet_death(id, timestamp)
    if !@pets.has_key?(id)
      # pet was probably summoned before the fight began
      pet_summon(id, self.started_at)
    end
    @pets[id][:active] = false
    @pets[id][:pet].ended_at = timestamp
    @pets[id][:pet].save
    @pet_kpis[@pets[id][:pet].name] ||= []
    @pet_kpis[@pets[id][:pet].name] << @pets[id][:pet].kpi_hash
  end

  def gain_external_buff_event(event)
    ability_name = spell_name(event['ability']['guid'])
    return if ability_name.nil?
    if self.uptime_abilities.keys.include? ability_name
      gain_uptime(ability_name, event['timestamp'])
    end
    if self.cooldown_abilities.keys.include? ability_name
      gain_cooldown(ability_name, event['timestamp'], self.cooldown_abilities[ability_name][:kpi_hash])
    end
    if self.potions.include? ability_name
      gain_cooldown(ability_name, event['timestamp'], {}, 'potion')
    end
    if self.procs.keys.include? ability_name
      gain_cooldown(ability_name, event['timestamp'], {}, 'proc')
    end
  end

  def lose_external_buff_event(event, force=true)
    ability_name = spell_name(event['ability']['guid'])
    return if ability_name.nil?
    if self.uptime_abilities.keys.include? ability_name
      drop_uptime(ability_name, event['timestamp'])
    end
    if self.cooldown_abilities.keys.include? ability_name
      drop_cooldown(ability_name, event['timestamp'], nil, force)
    end
    if (self.potions + self.procs.keys).include? ability_name
      drop_cooldown(ability_name, event['timestamp'], nil, force)
    end
  end

  def absorb_event(event)
    if @dying && event['sourceID'] == event['targetID']
      @kpi_parses[:death].details_hash[:deaths].last << {
        timestamp: event['timestamp'], 
        type: 'absorb',
        source: @actors[event['sourceID']],
        name: event['ability']['name'],
        amount: event['amount'],
        hp: @kpi_parses[:death].details_hash[:deaths].last.last[:hp],
      }
    end
  end

  def heal_event(event)
    if @dying && event['sourceID'] == event['targetID']
      percent = 100 * event['hitPoints'] / event['maxHitPoints'] rescue 0
      if percent > 30
        @dying = false
        @kpi_parses[:death].details_hash[:deaths].pop
      else
        @kpi_parses[:death].details_hash[:deaths].last << {
          timestamp: event['timestamp'], 
          type: 'heal',
          source: @actors[event['sourceID']],
          name: event['ability']['name'],
          amount: event['amount'],
          hp: percent,
        }
      end
    end
  end

  def receive_absorb_event(event)
    if @dying
      @kpi_parses[:death].details_hash[:deaths].last << {
        timestamp: event['timestamp'], 
        type: 'absorb',
        source: @actors[event['sourceID']],
        name: event['ability']['name'],
        amount: event['amount'],
        hp: @kpi_parses[:death].details_hash[:deaths].last.last[:hp],
      }
    end
    # ignore self-absorbs because they will already have been recorded
    return false if event['sourceID'] == event['targetID'] 
    # overwrite
  end

  def receive_heal_event(event)
    if @dying && event['hitPoints'].to_i > 0 && event['maxHitPoints'].to_i > 0
      percent = 100 * event['hitPoints'].to_i / event['maxHitPoints'].to_i
      if percent > 30
        @dying = false
        @kpi_parses[:death].details_hash[:deaths].pop
      else
        @kpi_parses[:death].details_hash[:deaths].last << {
          timestamp: event['timestamp'], 
          type: 'heal',
          source: @actors[event['sourceID']],
          name: event['ability']['name'],
          amount: event['amount'],
          hp: percent,
        }
      end
    end
    # ignore self-heals because they will already have been recorded
    return false if event['sourceID'] == event['targetID'] 
    # overwrite
  end

  def receive_damage_event(event)
    if event.has_key?('hitPoints') && event['maxHitPoints'].to_i > 0 && (percent = 100 * event['hitPoints'].to_i / event['maxHitPoints'].to_i) <= 30
      @kpi_parses[:death].details_hash[:deaths] << [] if !@dying
      @dying = true
      @kpi_parses[:death].details_hash[:deaths].last << {
        timestamp: event['timestamp'], 
        type: 'damage',
        source: @actors[event['sourceID']],
        name: event['ability']['name'],
        amount: event['amount'],
        hp: percent,
      }
      if percent == 0
        @kpi_parses[:death].kpi_hash[:death_count] += 1
        @kpi_parses[:death].details_hash[:deaths].last << {
            timestamp: event['timestamp'], 
            type: 'death',
            overkill: event['overkill'].to_i,
            hp: 0,
          }
        save_cast_detail(event, event['ability']['name'], 'death')
        @dying = false
        unless @dead
          # in case you died twice in a row and cast nothing in between
          self.kpi_hash[:dead_time] = self.kpi_hash[:dead_time].to_i - event['timestamp']
        end
        @dead = true
      end
    end
  end

  # setters

  def create_kpi_parses
    @kpi_parses[:dps] = KpiParse.new(fight_parse_id: self.id, name: :dps, kpi_hash: {player_damage_done: 0, pet_damage_done: 0}, details_hash: {})
    @kpi_parses[:death] = KpiParse.new(fight_parse_id: self.id, name: :death, kpi_hash: {death_count: 0}, details_hash: {deaths: []})
  end

  def set_actors(actors)
    @actors = {}
    actors.each do |id, hash|
      @actors[id] = pet_name(hash[:guid]) || hash[:name]
      @player_ids << id if hash[:player]
    end
  end

  def gain_cooldown(name, timestamp, kpi_hash = {}, cd_type = nil, key = nil)
    key ||= name
    cd_type ||= 'cd'
    return if !@cooldowns[key].nil? && @cooldowns[key][:active] && !@cooldowns[key][:temp]
    @cooldowns[key] ||= {active: false, buffer: 0, cp: nil}
    begin
      CooldownParse.destroy(@cooldowns[key][:cp].id) if @cooldowns[key][:temp] && !@cooldowns[key][:cp].nil?
    rescue
    end
    @cooldowns[key][:active] = true
    @cooldowns[key][:temp] = false
    @cooldowns[key][:cp] = CooldownParse.new(fight_parse_id: self.id, cd_type: cd_type, name: name, kpi_hash: kpi_hash, started_at: timestamp)
    self.track_casts.each do |spell, hash|
      if hash[:buff] == name && self.casts_hash.has_key?("#{spell}_waste") && self.casts_hash["#{spell}_waste"][:off_cd]
        # save_cast_detail({}, spell, 'off_cd', nil, timestamp)
        @cds.delete(spell)
        self.casts_hash["#{spell}_waste"][:waste] -= timestamp
      end
    end
  end

  def drop_cooldown(name, timestamp, cd_type = nil, force = true, key = nil)
    key ||= name
    cd_type ||= 'cd'
    if !@cooldowns.has_key?(key)
      if self.procs.keys.include? key
        gain_cooldown(name, self.started_at, {}, 'proc', key)
      elsif self.potions.include? key
        gain_cooldown(name, self.started_at, {}, 'potion', key)
      else
        return
      end
    end

    return if !@cooldowns[key][:active] && !@cooldowns[key][:casting]

    if force
      @cooldowns[key][:buffer] = timestamp unless @cooldowns[key][:buffer] > 0
    else
      if @cooldowns[key][:buffer] == 0 # allow for a buffer time, in case a buff is dropped before damage is recorded
        @cooldowns[key][:buffer] = timestamp
        return false
      elsif (@cooldowns[key][:buffer] - timestamp).abs <= 30 # 30ms is probably enough of a buffer
        return false # don't drop the cooldown yet, because we're still in the buffer time
      end
    end
    # buffer time has expired
    if @cooldowns[key][:buffer].nil?
      @cooldowns[key][:cp].ended_at ||= self.ended_at
    else
      @cooldowns[key][:cp].ended_at = @cooldowns[key][:buffer]
    end
    @cooldowns[key][:cp].save
    if @cooldowns[key][:temp] && self.track_casts.has_key?(key)
      # kind of hacky, but increment casts if this was a buff we're tracking
      self.casts_hash[key].unshift(self.started_at)
    end
    @cooldowns[key][:active] = false
    @cooldowns[key][:temp] = false
    @cooldowns[key][:buffer] = 0
    @kpis[name] ||= []
    @kpis[name] << @cooldowns[key][:cp].kpi_hash

    self.track_casts.each do |spell, hash|
      if hash[:buff] == name && self.casts_hash.has_key?("#{spell}_waste") && self.casts_hash["#{spell}_waste"][:off_cd]
        self.casts_hash["#{spell}_waste"][:waste] += timestamp || self.ended_at
      end
    end
    return true
  end

  def apply_buff(name, timestamp, kpi_hash = {})
    if @buffs[name][:bp].nil?
      @buffs[name][:bp] = BuffParse.new(
        fight_parse_id: self.id, 
        name: name, 
        kpi_hash: kpi_hash,
        uptimes_array: [{started_at: timestamp, ended_at: nil}], 
        downtimes_array: [],
        stacks_array: [{stacks: 1, started_at: timestamp, ended_at: timestamp}])
    elsif !@buffs[name][:active] || @buffs[name][:temp]
      if @buffs[name][:bp].downtimes_array.size > 0
        if @buffs[name][:bp].downtimes_array.last[:started_at] == timestamp
          # downtime lasted zero seconds, probably was there because of buff refresh
          @buffs[name][:bp].downtimes_array.pop 
        else
          @buffs[name][:bp].downtimes_array.last[:ended_at] = timestamp
        end
      end
      if @buffs[name][:bp].stacks_array.size > 0
        @buffs[name][:bp].stacks_array.last[:ended_at] = timestamp
      end
      @buffs[name][:bp].uptimes_array << {started_at: timestamp, ended_at: nil}
      @buffs[name][:bp].stacks_array << {stacks: 1, started_at: timestamp, ended_at: timestamp}
    end
    @buffs[name][:active] = true
    @buffs[name][:temp] = false
    @buff_uptimes << name if !self.buff_abilities[name].has_key?(:target_stacks) && !@buff_uptimes.include?(name)
  end

  def apply_buff_stack(name, stacks, timestamp)
    if !@buffs.has_key?(name) || (!@buffs[name][:active] && !@buffs[name][:temp]) || @buffs[name][:bp].nil?
      apply_buff(name, timestamp, self.buff_abilities[name]) 
    end
    @buffs[name][:bp].stacks_array.last[:ended_at] = timestamp
    @buffs[name][:bp].stacks_array << {stacks: stacks, started_at: timestamp, ended_at: timestamp}
    @buffs[name][:active] = true
    @buff_uptimes << name if stacks >= self.buff_abilities[name][:target_stacks].to_i && !@buff_uptimes.include?(name)
  end

  def remove_buff(name, timestamp)
    return if !@buffs.has_key?(name) || (!@buffs[name][:active] && !@buffs[name][:temp])
    apply_buff(name, self.started_at, self.buff_abilities[name]) if @buffs[name][:temp] || @buffs[name][:bp].nil?
    @buffs[name][:bp].uptimes_array.last[:ended_at] = timestamp unless @buffs[name][:bp].uptimes_array.size == 0
    @buffs[name][:bp].downtimes_array << {started_at: timestamp, ended_at: nil}
    @buffs[name][:bp].save
    @buffs[name][:active] = false
    if @buffs[name][:bp].stacks_array.count > 0
      @buffs[name][:bp].stacks_array.last[:ended_at] = timestamp
    end
    if timestamp != self.ended_at
      @buffs[name][:bp].stacks_array << {stacks: 0, started_at: timestamp, ended_at: timestamp}
    end
    @kpis[name] ||= []
    @kpis[name] << @buffs[name][:bp].kpi_hash
    @buff_uptimes.delete(name)
  end

  def remove_buff_stack(name, stacks, timestamp)
    return if !@buffs.has_key?(name) || !@buffs[name][:active]
    @buffs[name][:bp].stacks_array.last[:ended_at] = timestamp
    @buffs[name][:bp].stacks_array << {stacks: stacks, started_at: timestamp, ended_at: timestamp}
    @buff_uptimes.delete(name) if stacks < self.buff_abilities[name][:target_stacks].to_i && @buff_uptimes.include?(name)
  end

  def apply_external_buff(name, target_id, target_instance, timestamp, kpi_hash = {})
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if !@external_buffs[name].has_key?(target_key)
      
      @external_buffs[name][target_key] = {
        bp: ExternalBuffParse.new(fight_parse_id: self.id, 
          name: name, 
          target_id: target_id, 
          target_name: @actors[target_id],
          target_instance: target_instance,
          kpi_hash: kpi_hash,
          uptimes_array: [{started_at: timestamp, ended_at: nil}], 
          downtimes_array: [],
          stacks_array: [{stacks: 1, started_at: timestamp, ended_at: timestamp}]), 
        active: true}
    elsif !@external_buffs[name][target_key][:active]
      if @external_buffs[name][target_key][:bp].downtimes_array.size > 0
        @external_buffs[name][target_key][:bp].downtimes_array.last[:ended_at] = timestamp
      end
      if @external_buffs[name][target_key][:bp].stacks_array.size > 0
        @external_buffs[name][target_key][:bp].stacks_array.last[:ended_at] = timestamp
      end
      @external_buffs[name][target_key][:bp].uptimes_array << {started_at: timestamp, ended_at: nil}
      @external_buffs[name][target_key][:bp].stacks_array << {stacks: 1, started_at: timestamp, ended_at: timestamp}
    end
    @external_buffs[name][target_key][:active] = true
    @external_buff_uptimes[name] << target_key if !self.external_buff_abilities[name].has_key?(:target_stacks) && !@external_buff_uptimes[name].include?(target_key)
    if @external_buff_uptimes[name].count > 0 && !@uptimes[name][:active]
      gain_uptime(name, timestamp)
    end
  end

  def apply_external_buff_stack(name, target_id, target_instance, stacks, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if !@external_buffs[name].has_key?(target_key) || !@external_buffs[name][target_key][:active]
      apply_external_buff(name, target_id, target_instance, timestamp, self.external_buff_abilities[name]) 
    end
    @external_buffs[name][target_key][:bp].stacks_array.last[:ended_at] = timestamp
    @external_buffs[name][target_key][:bp].stacks_array << {stacks: stacks, started_at: timestamp, ended_at: timestamp}
    @external_buffs[name][target_key][:active] = true
    @external_buff_uptimes[name] << target_key if stacks >= self.external_buff_abilities[name][:target_stacks].to_i && !@external_buff_uptimes[name].include?(target_key)
    if @external_buff_uptimes[name].count > 0 && !@uptimes[name][:active]
      gain_uptime(name, timestamp)
    end
  end

  def remove_external_buff(name, target_id, target_instance, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    return if !@external_buffs[name].has_key?(target_key) || !@external_buffs[name][target_key][:active]
    @external_buffs[name][target_key][:bp].uptimes_array.last[:ended_at] = timestamp unless @external_buffs[name][target_key][:bp].uptimes_array.size == 0
    @external_buffs[name][target_key][:bp].downtimes_array << {started_at: timestamp, ended_at: nil}
    @external_buffs[name][target_key][:bp].save
    @external_buffs[name][target_key][:active] = false
    if @external_buffs[name][target_key][:bp].stacks_array.count > 0
      @external_buffs[name][target_key][:bp].stacks_array.last[:ended_at] = timestamp
    end
    if timestamp != self.ended_at
      @external_buffs[name][target_key][:bp].stacks_array << {stacks: 0, started_at: timestamp, ended_at: timestamp}
    end
    @kpis[name] ||= []
    @kpis[name] << @external_buffs[name][target_key][:bp].kpi_hash
    @external_buff_uptimes[name].delete(target_key)
    if @external_buff_uptimes[name].count == 0 && @uptimes[name][:active]
      drop_uptime(name, timestamp)
    end
  end

  def remove_external_buff_stack(name, target_id, target_instance, stacks, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if !@external_buffs[name].has_key?(target_key) || !@external_buffs[name][target_key][:active]
      apply_external_buff(name, target_id, target_instance, timestamp, self.external_buff_abilities[name]) 
    end
    @external_buffs[name][target_key][:bp].stacks_array.last[:ended_at] = timestamp
    @external_buffs[name][target_key][:bp].stacks_array << {stacks: stacks, started_at: timestamp, ended_at: timestamp}
    @external_buffs[name][target_key][:active] = true
    @external_buff_uptimes[name].delete(target_key) if stacks < self.external_buff_abilities[name][:target_stacks].to_i
  end

  def apply_debuff(name, target_id, target_instance, target_is_friendly, timestamp, kpi_hash = {})
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if !@debuffs[name].has_key?(target_key)
      
      @debuffs[name][target_key] = {
        dp: DebuffParse.new(fight_parse_id: self.id, 
          name: name, 
          target_id: target_id, 
          target_name: @actors[target_id],
          target_instance: target_instance,
          kpi_hash: kpi_hash,
          uptimes_array: [{started_at: timestamp, ended_at: timestamp}], 
          downtimes_array: [],
          stacks_array: [{stacks: 1, started_at: timestamp, ended_at: timestamp}]), 
        active: true}
    elsif !@debuffs[name][target_key][:active]
      if @debuffs[name][target_key][:dp].downtimes_array.size > 0
        @debuffs[name][target_key][:dp].downtimes_array.last[:ended_at] = timestamp
      end
      if @debuffs[name][target_key][:dp].stacks_array.size > 0
        @debuffs[name][target_key][:dp].stacks_array.last[:ended_at] = timestamp
      end
      @debuffs[name][target_key][:dp].uptimes_array << {started_at: timestamp, ended_at: timestamp}
      @debuffs[name][target_key][:dp].stacks_array << {stacks: 1, started_at: timestamp, ended_at: timestamp}
    end
    @pandemic[name] ||= {}
    @debuffs[name][target_key][:dp].kpi_hash[:pandemic] = @pandemic[name][target_key].to_i
    @debuffs[name][target_key][:active] = true
    @debuff_uptimes[name] << target_key if !self.debuff_abilities[name].has_key?(:target_stacks) && !@debuff_uptimes[name].include?(target_key)
    check_for_debuffs(target_id, target_instance, timestamp) if !target_is_friendly
  end

  def apply_debuff_stack(name, target_id, target_instance, target_is_friendly, stacks, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if !@debuffs[name].has_key?(target_key) || !@debuffs[name][target_key][:active]
      apply_debuff(name, target_id, target_instance, target_is_friendly, timestamp, self.debuff_abilities[name]) 
    end
    @debuffs[name][target_key][:dp].stacks_array.last[:ended_at] = timestamp
    @debuffs[name][target_key][:dp].stacks_array << {stacks: stacks, started_at: timestamp, ended_at: timestamp}
    @debuffs[name][target_key][:active] = true
    @debuff_uptimes[name] << target_key if stacks >= self.debuff_abilities[name][:target_stacks].to_i && !@debuff_uptimes[name].include?(target_key)
  end

  def remove_debuff(name, target_id, target_instance, target_is_friendly, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    return if !@debuffs[name].has_key?(target_key) || !@debuffs[name][target_key][:active]
    @debuffs[name][target_key][:dp].uptimes_array.last[:ended_at] = timestamp unless @debuffs[name][target_key][:dp].uptimes_array.size == 0
    @debuffs[name][target_key][:dp].downtimes_array << {started_at: timestamp, ended_at: timestamp}
    @debuffs[name][target_key][:dp].save
    @debuffs[name][target_key][:active] = false
    if @debuffs[name][target_key][:dp].stacks_array.count > 0
      @debuffs[name][target_key][:dp].stacks_array.last[:ended_at] = timestamp
    end
    if timestamp != self.ended_at
      @debuffs[name][target_key][:dp].stacks_array << {stacks: 0, started_at: timestamp, ended_at: timestamp}
    end
    @kpis[name] ||= []
    @kpis[name] << @debuffs[name][target_key][:dp].kpi_hash
    @debuff_uptimes[name].delete(target_key)
    check_for_debuffs(target_id, target_instance, timestamp) if !target_is_friendly
  end

  def remove_debuff_stack(name, target_id, target_instance, target_is_friendly, stacks, timestamp)
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    if !@debuffs[name].has_key?(target_key) || !@debuffs[name][target_key][:active]
      apply_debuff(name, target_id, target_instance, target_is_friendly, timestamp, self.debuff_abilities[name]) 
    end
    @debuffs[name][target_key][:dp].stacks_array.last[:ended_at] = timestamp
    @debuffs[name][target_key][:dp].stacks_array << {stacks: stacks, started_at: timestamp, ended_at: timestamp}
    @debuffs[name][target_key][:active] = true
    @debuff_uptimes[name].delete(target_key) if stacks < self.debuff_abilities[name][:target_stacks].to_i
  end

  def check_for_debuffs(target_id, target_instance, timestamp)
    # check if debuffs should be active but aren't
    target_key = "#{target_id.to_i}-#{target_instance.to_i}"
    @debuffs.each do |name, debuffs_list|
      if debuffs_list.has_key?(target_key) && debuffs_list[target_key][:dp].uptimes_array.size != 0
        if debuffs_list[target_key][:active]      
          debuffs_list[target_key][:dp].uptimes_array.last[:ended_at] = timestamp
        else
          if timestamp - debuffs_list[target_key][:dp].downtimes_array.last[:ended_at].to_i >= 10000
            # start a new downtime if target was inactive for more than 10 seconds
            debuffs_list[target_key][:dp].downtimes_array << {started_at: timestamp, ended_at: timestamp}
          else
            debuffs_list[target_key][:dp].downtimes_array.last[:ended_at] = timestamp
          end
        end
        debuffs_list[target_key][:dp].stacks_array.last[:ended_at] = timestamp
      else
        kpi_hash = self.debuff_abilities[name] || {}
        debuffs_list[target_key] = {
          dp: DebuffParse.new(fight_parse_id: self.id, 
            name: name, 
            target_id: target_id, 
            target_name: @actors[target_id],
            target_instance: target_instance,
            kpi_hash: kpi_hash,
            uptimes_array: [], 
            downtimes_array: [{started_at: timestamp, ended_at: timestamp}],
            stacks_array: [{stacks: 0, started_at: timestamp, ended_at: timestamp}]),
          active: false}
      end
    end
  end

  def gain_uptime(name, timestamp)
    @uptimes[name] ||= {active: false, uptime: 0}
    if !@uptimes[name][:active]
      @uptimes[name][:active] = true
      @uptimes[name][:uptime] -= timestamp
    end
  end

  def drop_uptime(name, timestamp)
    gain_uptime(name, self.started_at) if @uptimes[name].nil?
    if @uptimes[name][:uptime] == 0 # already up when fight started
      @uptimes[name][:uptime] -= self.started_at 
      @uptimes[name][:active] = true
    end
    if @uptimes[name][:active]
      @uptimes[name][:active] = false
      @uptimes[name][:uptime] += timestamp
    end
  end

  def is_active?(cd_name, timestamp)
    return false if @cooldowns[cd_name].nil? || @cooldowns[cd_name][:cp].nil?
    return false if @cooldowns[cd_name][:temp]
    return false if timestamp < @cooldowns[cd_name][:cp].started_at
    return false if !@cooldowns[cd_name][:cp].ended_at.nil? && timestamp > @cooldowns[cd_name][:cp].ended_at
    return true
  end

  def apply_external_cooldown(name, target_id, target_name, timestamp, kpi_hash={})
    key = "#{name}-#{target_name}"
    @cooldowns[key] ||= {active: false, buffer: 0, cp: nil}
    if @cooldowns[key][:temp] && !@cooldowns[key][:cp].nil?
      begin
        ExternalCooldownParse.destroy(@cooldowns[key][:cp].id) 
      rescue
      end
    elsif @cooldowns[key][:active]
      drop_external_cooldown(name, target_id, target_name, timestamp)
    end
    @cooldowns[key][:cp] = ExternalCooldownParse.new(fight_parse_id: self.id, target_id: target_id, target_name: target_name, cd_type: 'cd', name: name, kpi_hash: kpi_hash, started_at: timestamp)
    @cooldowns[key][:active] = true
    @cooldowns[key][:temp] = false
  end

  def drop_external_cooldown(name, target_id, target_name, timestamp)
    key = "#{name}-#{target_name}"
    return if @cooldowns[key].nil? || @cooldowns[key][:cp].nil?
    if @cooldowns[key][:temp] && self.track_casts.has_key?(name)
      # kind of hacky, but increment casts if this was a buff we're tracking
      self.casts_hash[name].unshift(self.started_at)
    end
    @cooldowns[key][:cp].ended_at = timestamp
    @cooldowns[key][:cp].save
    @cooldowns[key][:active] = false
    @cooldowns[key][:temp] = false
    @kpis[name] ||= []
    @kpis[name] << @cooldowns[key][:cp].kpi_hash
  end

  def clean
    self.resources_hash[:abc_wasted] = @abc_wasted.round(1) if @check_abc
    if self.resources_hash.has_key?(:capped_time)
      self.resources_hash[:capped_time] = self.resources_hash[:capped_time].to_i / 1000
    end
    self.kpi_hash[:dead_time] = self.kpi_hash[:dead_time].to_i + self.ended_at if @dead

    @cooldowns.each do |name, hash|
      begin
        CooldownParse.destroy(hash[:cp].id) if hash[:temp]
      rescue ActiveRecord::RecordNotFound
      end
      drop_cooldown(name, nil, nil, true)  if !hash[:temp] && (hash[:active] || hash[:casting])
    end
    @pets.each do |pet_id, hash|
      ended_at = hash[:pet].ended_at || self.ended_at
      pet_death(pet_id, ended_at) if hash[:active]
    end
    @uptimes.each do |name, hash|
      drop_uptime(name, self.ended_at) if hash[:active]
    end
    @buff_uptimes.each do |name|
      drop_uptime(name, self.ended_at)
    end
    @buffs.each do |name, buff|
      next if buff[:bp].nil?
      buff[:bp].uptimes_array.last[:ended_at] = self.ended_at if buff[:active]
      if buff[:bp].downtimes_array.size > 0 && buff[:bp].downtimes_array.last[:ended_at].nil?
        buff[:bp].downtimes_array.delete_at(-1)
        buff[:bp].stacks_array.delete_at(-1) unless buff[:bp].stacks_array.size == 0
      elsif !buff[:active]
        buff[:bp].stacks_array.last[:ended_at] = buff[:bp].downtimes_array.last[:ended_at]
      else
        buff[:bp].stacks_array.last[:ended_at] = self.ended_at
      end
      buff[:bp].kpi_hash[:uptime] = buff[:bp].uptimes_array.inject(0) {|sum, up| sum + up[:ended_at] - up[:started_at]}
      buff[:bp].kpi_hash[:downtime] = buff[:bp].downtimes_array.inject(0) {|sum, down| sum + down[:ended_at] - down[:started_at]}
      if self.buff_abilities[name].has_key?(:target_stacks)
        buff[:bp].kpi_hash[:stacks_uptime] = buff[:bp].stacks_array.map{|stack| stack[:stacks] >= self.buff_abilities[name][:target_stacks] ? (stack[:ended_at] - stack[:started_at]) : 0}.sum
      end
      if buff[:bp].kpi_hash[:uptime] > 0
        buff[:bp].save
        @kpis[name] ||= []
        @kpis[name] << @buffs[name][:bp].kpi_hash
      else
        buff[:bp].destroy
      end
    end
    @debuff_uptimes.each do |name, targets|
      drop_uptime(name, self.ended_at) if targets.count > 0
    end
    @debuffs.each do |name, debuffs_list|
      debuffs_list.each do |target, debuff|
        # debuff[:dp].uptimes_array.last[:ended_at] = self.ended_at if debuff[:active]
        if debuff[:dp].downtimes_array.size > 0 && debuff[:dp].downtimes_array.last[:ended_at].nil?
          debuff[:dp].downtimes_array.delete_at(-1)
          debuff[:dp].stacks_array.delete_at(-1) unless debuff[:dp].stacks_array.size == 0
        elsif !debuff[:active]
          debuff[:dp].stacks_array.last[:ended_at] = debuff[:dp].downtimes_array.last[:ended_at]
        else
          debuff[:dp].stacks_array.last[:ended_at] = self.ended_at
        end
        debuff[:dp].kpi_hash[:uptime] = debuff[:dp].uptimes_array.inject(0) {|sum, up| sum + up[:ended_at] - up[:started_at]}
        debuff[:dp].kpi_hash[:downtime] = debuff[:dp].downtimes_array.inject(0) {|sum, down| sum + down[:ended_at] - down[:started_at]}
        if self.debuff_abilities[name].has_key?(:target_stacks)
          debuff[:dp].kpi_hash[:stacks_uptime] = debuff[:dp].stacks_array.map{|stack| stack[:stacks] >= self.debuff_abilities[name][:target_stacks] ? (stack[:ended_at] - stack[:started_at]) : 0}.sum
        end
        debuff[:dp].kpi_hash[:uptime] > 0 ? debuff[:dp].save : debuff[:dp].destroy
      end
    end
    @external_buff_uptimes.each do |name, targets|
      drop_uptime(name, self.ended_at) if targets.count > 0
    end
    @external_buffs.each do |name, buffs_list|
      buffs_list.each do |target, buff|
        buff[:bp].uptimes_array.last[:ended_at] = self.ended_at if buff[:active]
        if buff[:bp].downtimes_array.size > 0 && buff[:bp].downtimes_array.last[:ended_at].nil?
          buff[:bp].downtimes_array.delete_at(-1)
          buff[:bp].stacks_array.delete_at(-1) unless buff[:bp].stacks_array.size == 0
        elsif !buff[:active]
          buff[:bp].stacks_array.last[:ended_at] = buff[:bp].downtimes_array.last[:ended_at]
        else
          buff[:bp].stacks_array.last[:ended_at] = self.ended_at
        end
        buff[:bp].kpi_hash[:uptime] = buff[:bp].uptimes_array.inject(0) {|sum, up| sum + up[:ended_at] - up[:started_at]}
        buff[:bp].kpi_hash[:downtime] = buff[:bp].downtimes_array.inject(0) {|sum, down| sum + down[:ended_at] - down[:started_at]}
        if self.external_buff_abilities[name].has_key?(:target_stacks)
          buff[:bp].kpi_hash[:stacks_uptime] = buff[:bp].stacks_array.map{|stack| stack[:stacks] >= self.external_buff_abilities[name][:target_stacks] ? (stack[:ended_at] - stack[:started_at]) : 0}.sum
        end
        buff[:bp].kpi_hash[:uptime] > 0 ? buff[:bp].save : buff[:bp].destroy
      end
    end
    @kpi_parses.each do |name, kpi_parse|
      kpi_parse.save
    end

    
    save_casts_score
    calculate_scores if self.kill?

    CooldownParse.where("fight_parse_id = #{self.id} AND ended_at IS NULL").delete_all
    ExternalCooldownParse.where("fight_parse_id = #{self.id} AND ended_at IS NULL").delete_all
  end

  def save_casts_score
    score = max_score = 0
    self.track_casts.each do |spell, hash|
      next if self.casts_hash[spell].size == 0 && hash[:optional]
      next if hash[:no_score]
      # if self.casts_hash.has_key?("#{spell}_waste") && self.casts_hash["#{spell}_waste"][:off_cd]
      #   self.casts_hash["#{spell}_waste"][:waste] += self.ended_at
      # end
      unless hash[:cd].nil?
        max = casts_possible(hash).to_i * hash[:cd].to_i
        max_score += max
        score += [self.casts_hash[spell].size * hash[:cd].to_i, max].min
      end
    end
    max_score = score if score > max_score
    self.kpi_hash[:casts_score] = [100, 100 * score / max_score].min rescue 0
    S3_BUCKET.object("casts_details/#{self.report_id}_#{self.fight_id}_#{self.player_id}.json").put(body: @casts_details.to_json)
  end

  def calculate_scores
    self.casts_score = self.kpi_hash[:casts_score].to_i

    # save cooldown damage score for dps classes
    if false
      cooldown_damage_score = 0
      damages = []
      self.dps_abilities.merge(self.dps_buff_abilities).each do |name, hash|
        damages << @kpis[name].map{|kpi| kpi[:damage_done].to_i + kpi[:extra_damage].to_i + kpi[:pet_damage_done].to_i}.sum rescue 0
      end
      total_cooldown_damage = damages.sum
      total_damage = self.kpi_hash[:player_damage_done].to_i + self.kpi_hash[:player_pet_damage_done].to_i
      damages.each do |damage|
        cooldown_damage_score += (1.0 * damage / total_cooldown_damage) * (1.0 * damage / total_damage)
      end
      begin
        self.cooldowns_score = (cooldown_damage_score * 100).to_i
      rescue
      end
    end
  end

  def aggregate_dps_cooldowns
    self.dps_abilities.merge(self.dps_buff_abilities).each do |name, hash|
      key = hash[:key] || name.downcase.strip.gsub(' ', '_').gsub(/[^\w-]/, '')
      damage = @kpis[name].map{|kpi| kpi[:damage_done].to_i + kpi[:extra_damage].to_i + kpi[:pet_damage_done].to_i}.sum rescue 0
      self.cooldowns_hash["#{key}_damage".to_sym] = damage
    end
  end

  def aggregate_debuffs
    self.debuff_abilities.each do |name, hash|
      # next if !hash[:score]
      key = hash[:key] || name.downcase.strip.gsub(' ', '_').gsub(/[^\w-]/, '')
      if hash[:single_target]
        self.resources_hash["#{key}_uptime".to_sym] = @uptimes[name][:uptime] rescue 0
      else
        self.resources_hash["#{key}_uptime".to_sym] = 0
        self.resources_hash["#{key}_downtime".to_sym] = 0
        self.debuff_parses.where(name: name).each do |debuff|
          self.resources_hash["#{key}_uptime".to_sym] += debuff.kpi_hash[:stacks_uptime] || debuff.kpi_hash[:uptime].to_i
          self.resources_hash["#{key}_downtime".to_sym] += debuff.kpi_hash[:downtime].to_i
        end
      end
    end
  end

end