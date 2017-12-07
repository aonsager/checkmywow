desc "This task is called by the Heroku scheduler add-on"
task :clear_stuck_tasks => :environment do
  kill_time = ENV['kill_time'] || 600
  Resque.workers.each {|w| w.unregister_worker if w.processing['run_at'] && !w.processing['run_at'].nil? && Time.now - w.processing['run_at'].to_time > kill_time}
  # retry reports in the queue for longer than 15 minutes, as it probably got stuck
  Report.where("status=5 and updated_at < '#{Time.now - 15.minutes}'").pluck(:report_id).each do |id|
    Resque.enqueue(Parser, id)
  end
end

task :log_queue_size => :environment do
  working = Resque.working.size
  parse = Resque.size(:parse)
  single_parse = Resque.size(:single_parse)
  Resque.logger.info("Queue Sizes: parse=#{parse} single_parse=#{single_parse} working=#{working} total=#{working+parse+single_parse}")
end

task :retry_dirtyexit => :environment do
  redis = Resque.redis

  (0...Resque::Failure.count).each do |i|
    serialized_job = redis.lindex(:failed, i)
    job = Resque.decode(serialized_job)

    next if job.nil?
    if job['exception'] == 'Resque::DirtyExit'
      puts "Retry dirty #{job['payload']['class']}"
      Resque::Failure.requeue(i)
      Resque::Failure.remove(i)
    end
  end
end

task :retry_empty => :environment do
  Progress.where("model_type = 'Report' AND updated_at BETWEEN ? AND ?", Time.now - 6.hours, Time.now - 1.hours).pluck(:model_id).each do |id|
    Resque.enqueue(Parser, id)
    puts "Retry stuck Report #{id}"
  end
  Fail.where("model_type = 'Report' AND status = 'empty' AND updated_at > ?", Time.now - 6.hours).pluck(:model_id).each do |id|
    Resque.enqueue(Parser, id)
    puts "Retry empty Report #{id}"
  end
  Progress.where("model_type = 'FightParse' AND updated_at BETWEEN ? AND ?", Time.now - 6.hours, Time.now - 1.hours).pluck(:model_id).each do |id|
    Resque.enqueue(BatchParser, id)
    puts "Retry stuck FightParse #{id}"
  end
  Fail.where("model_type = 'FightParse' AND status = 'empty' AND updated_at > ?", Time.now - 6.hours).pluck(:model_id).each do |id|
    Resque.enqueue(BatchParser, id)
    puts "Retry empty FightParse #{id}"
  end
  Progress.where("model_type = 'Fight' AND updated_at BETWEEN ? AND ?", Time.now - 6.hours, Time.now - 1.hours).pluck(:model_id).each do |id|
    Fight.find(id).queue_healing_parses
    puts "Retry stuck Fight (Healing Parse) #{id}"
  end
  Fail.where("model_type = 'Fight' AND status = 'empty' AND updated_at > ?", Time.now - 6.hours).pluck(:model_id).each do |id|
    Fight.find(id).queue_healing_parses
    puts "Retry empty Fight (Healing Parse) #{id}"
  end
end

task :retry_failed => :environment do
  redis = Resque.redis

  (0...Resque::Failure.count).each do |i|
    serialized_job = redis.lindex(:failed, 0)
    job = Resque.decode(serialized_job)

    next if job.nil?
    puts "Retry failed #{job['payload']['class'] rescue ''}"
    Resque::Failure.requeue(0)
    Resque::Failure.remove(0)
  end
end