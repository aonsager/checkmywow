class Fight < ActiveRecord::Base
  belongs_to :report
  enum status: [:unprocessed, :processing, :done, :failed, :empty, :queued, :cached]

  def parsed?
    return self.done?
  end

  def fight_time
    return (self.ended_at - self.started_at) / 1000 rescue 0
  end

  def fight_time_s
    return Time.at(self.fight_time).strftime("%M:%S")
  end

  def full_name
    return self.name + " " + self.kill_label
  end

  def kill_label
    return "#{DifficultyType.label(self.difficulty)} #{self.kill? ? 'Kill' : "#{self.boss_percent / 100}% Wipe"} (#{self.fight_time_s})" rescue ''
  end

  def queue_healing_parses
    return false if self.done?
    HealingParse.where(report_id: self.report_id, fight_id: self.fight_id).destroy_all
    player_ids = FightParseRecord.where(report_id: self.report_id, fight_id: self.fight_id).pluck(:player_id).uniq
    begin
      progress = Progress.find_or_create_by(model_type: 'Fight', model_id: self.id)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    progress.update_attributes(current: 0, finish: player_ids.count)
    player_ids.each do |player_id|
      Resque.enqueue(HealingParser, self.id, player_id)
    end
    self.processing!
  end

end