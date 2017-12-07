class HealingParse < ActiveRecord::Base
  belongs_to :fight
  serialize :details_hash, Hash
  serialize :kpi_hash, Hash
  default_scope { order(created_at: :asc) }

  def start_time(fight_started)
    seconds = (self.started_at - fight_started) / 1000
    return "#{seconds / 60}:#{(seconds % 60).to_s.rjust(2, "0")}"
  end

  def end_time(fight_started)
    seconds = (self.ended_at - fight_started) / 1000
    return "#{seconds / 60}:#{(seconds % 60).to_s.rjust(2, "0")}"
  end

  def time_s(fight_started)
    return "#{self.start_time(fight_started)} - #{self.end_time(fight_started)}"
  end

  def time
    return [(self.ended_at - self.started_at) / 1000, 1].max
  end
end