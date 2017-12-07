class FightParseRecord < ActiveRecord::Base
  belongs_to :fight, foreign_key: :fight_guid
  enum status: [:unprocessed, :queued, :processing, :done, :failed, :empty, :unparsable]

  def exists?
    return !self.parsed_at.nil? && Time.now - self.parsed_at < 6.months
  end

  def expired?
    return false if self.parsed_at.nil?
    return self.parsed_at < Time.now - 6.months
  end

  def parsable?
    if !Zone.enabled_zones.include?(self.fight.zone_id)
      self.unparsable!
      return false 
    end
    klass = Object.const_get("FightParse::#{self.class_type}::#{self.spec}") rescue FightParse
    return true if self.find_fp.nil?
    return false if self.done? && (self.version == klass.latest_version)
    return true
  end

  def enqueue(batch = false, force = false)
    if !force
      return false if !self.parsable?
      return false if self.queued? || self.processing?
    end
    self.queued!
    if batch
      Resque.enqueue(BatchParser, self.id)
    else
      Resque.enqueue(SingleParser, self.id)
    end
  end

  def find_fp
    klass = Object.const_get("FightParse::#{self.class_type.capitalize}::#{self.spec.capitalize}") rescue FightParse
    fp = klass.find_by(report_id: report_id, fight_id: fight_id, player_id: player_id)
    if fp.nil? && self.done? && !self.expired?
      old_fp = FightParse.find_by(report_id: report_id, fight_id: fight_id, player_id: player_id)
      if old_fp.nil?
        self.unprocessed! 
      else
        fp = klass.create(old_fp.attributes)
      end
    elsif !fp.nil? && self.unprocessed?
      self.done!
    end
    return fp
  end

end