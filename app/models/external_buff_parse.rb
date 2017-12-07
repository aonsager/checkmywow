class ExternalBuffParse < ActiveRecord::Base
  belongs_to :fight_parse
  serialize :uptimes_array
  serialize :downtimes_array
  serialize :stacks_array
  serialize :kpi_hash, Hash
  serialize :details_hash, Hash
  default_scope { order(created_at: :asc) }

  def upratio
    return (100.0 * kpi_hash[:uptime] / (kpi_hash[:uptime] + kpi_hash[:downtime])).round(2)
  end

  def upratio_s(stacks = false)
    uptime = stacks == true ? kpi_hash[:stacks_uptime].to_i : kpi_hash[:uptime].to_i
    return "#{uptime / 1000}s / #{(kpi_hash[:uptime].to_i + kpi_hash[:downtime].to_i) / 1000}s"
  end

  def start_time
    seconds = (self.uptimes_array.first[:started_at] - self.fight_parse.started_at) / 1000
    return "#{seconds / 60}:#{(seconds % 60).to_s.rjust(2, "0")}"
  end

  def end_time
    if self.downtimes_array.size > 0
      seconds = (self.downtimes_array.last[:ended_at] - self.fight_parse.started_at) / 1000
    else
      seconds = (self.uptimes_array.last[:ended_at] - self.fight_parse.started_at) / 1000
    end
    return "#{seconds / 60}:#{(seconds % 60).to_s.rjust(2, "0")}"
  end

  def time_s
    return "#{self.start_time} - #{self.end_time}"
  end

  def time
    return (kpi_hash[:ended_at].to_i - kpi_hash[:started_at].to_i) / 1000
  end

end