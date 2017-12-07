class ExternalCooldownParse < ActiveRecord::Base
  belongs_to :fight_parse
  serialize :details_hash, Hash
  serialize :kpi_hash, Hash
  default_scope { order(started_at: :asc) }

  def start_time
    seconds = (self.started_at - self.fight_parse.started_at) / 1000
    return "#{seconds / 60}:#{(seconds % 60).to_s.rjust(2, "0")}"
  end

  def end_time
    seconds = (self.ended_at - self.fight_parse.started_at) / 1000
    return "#{seconds / 60}:#{(seconds % 60).to_s.rjust(2, "0")}"
  end

  def time_s
    return "#{self.start_time} - #{self.end_time}"
  end

  def time
    return [(self.ended_at - self.started_at) / 1000, 1].max
  end

end