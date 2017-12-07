require 'resque/errors'
class Parser
  include Resque::Plugins::UniqueJob
  @queue = :parse
  @report_id = 0
  @retried = false
  @started_at = 0

  def self.on_failure_reset(e, *args)
    report = Report.find_by(report_id: @report_id)
    if !report.nil?
      report.failed! 
      begin
        failure = Fail.find_or_create_by(model_type: 'Report', model_id: @report_id)
        failure.update_attributes(status: 'failed')
      rescue ActiveRecord::StaleObjectError
        retry
      end
    end
    begin
      Progress.where(model_type: 'Report', model_id: @report_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end
    Resque.logger.error("Error. Report #{@report_id}")
    Resque.logger.error(e)
    Resque.logger.error(e.backtrace[0]) unless e.backtrace.nil?
    Rollbar.error(e, "Report parse error", report_id: @report_id, :use_exception_level_filters => true)
  end

  def self.perform(report_id, retried=false)
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")
    @report_id = report_id
    @retried = retried
    @started_at = Time.now

    begin
      report = Report.find_or_create_by(report_id: @report_id)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    # import the fights
    tries = 3
    begin
      Resque.logger.info("WCL API  /fights/#{@report_id}") unless Rails.env.development?
      response = HTTParty.get("https://www.warcraftlogs.com:443/v1/report/fights/#{@report_id}?api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
      if response.code == 429
        raise RateLimitError
      else
        report_obj = JSON.parse(response.body)
      end
    rescue RateLimitError
      Resque.logger.info("Hit rate limit, sleeping")
      Resque.logger.info(response.headers)
      Resque.logger.info(response.body)
      sleep(60)
      retry
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT, JSON::ParserError, SocketError
      if (tries -= 1) > 0
        retry
      end
    end
    fights = report_obj['fights'] rescue nil
    fight_players = {}
    if fights.nil? && @retried
      report.empty!
      begin
        Progress.where(model_type: 'Report', model_id: @report_id).destroy_all
      rescue ActiveRecord::StaleObjectError
        retry
      end
      begin
        failure = Fail.find_or_create_by(model_type: 'Report', model_id: @report_id)
        failure.update_attributes(status: 'empty')
      rescue ActiveRecord::StaleObjectError
        retry
      end
      return 
    end

    begin
      progress = Progress.find_or_create_by(model_type: 'Report', model_id: report_id)
      progress.update_attributes(current: 0, finish: report_obj['fights'].size, message: "Importing fight list")
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
      retry
    end

    report_started_at = report_obj['start']
    report.update_attributes(
      title: report_obj['title'],
      zone: report_obj['zone'],
      started_at: Time.at(report_obj['start']/1000),
      ended_at: Time.at(report_obj['end']/1000),
      status: 'processing'
    )
    friendlies = {}
    report_obj['friendlies'].each do |friendly|
      friendlies[friendly['id']] = friendly
      next if friendly['type'] == 'Pet'
      friendly['fights'].each do |fight|
        fight_players[fight['id']] ||= []
        fight_players[fight['id']] << friendly['id']
      end
    end

    fights.each_with_index do |fight_obj, index|
      next unless fight_obj['boss'].to_i > 0 || fight_obj['name'].include?('Dummy')
      fight_id = fight_obj['id']
      begin
        fight = Fight.find_or_create_by(report_id: report_id, fight_id: fight_id)
      rescue ActiveRecord::RecordNotUnique
        retry
      end
      zone_id = Boss.find(fight_obj['boss'].to_i).zone_id rescue nil
      fight.update_attributes(
        name: fight_obj['name'],
        zone_id: zone_id,
        boss_id: fight_obj['boss'].to_i,
        size: fight_obj['size'],
        difficulty: fight_obj['difficulty'].to_i,
        kill: fight_obj['kill'],
        boss_percent: fight_obj['bossPercentage'],
        report_started_at: Time.at(report_started_at/1000),
        started_at: fight_obj['start_time'],
        ended_at: fight_obj['end_time'],
      )
      begin
        progress = Progress.find_or_create_by(model_type: 'Report', model_id: report_id)
        progress.update_attributes(current: index + 1, message: "Reading players from #{fight.name} #{fight.kill_label} [#{index+1}/#{fights.count}]")
      rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
        retry
      end       
      next if fight_players[fight_id].nil?
      fight_players[fight_id].each do |player_id|
        player_hash = friendlies[player_id]
        next if player_hash['type'] == 'NPC' || player_hash['type'] == 'Boss'
        ReportPlayer.find_or_create_by(report_id: @report_id, player_id: player_hash['guid'])
        player = Player.find_or_initialize_by(player_id: player_hash['guid'])
        player.assign_attributes(player_name: player_hash['name'], class_type: player_hash['type'].to_s.capitalize)
        player.boss_counts[fight.boss_id] ||= {}
        player.boss_counts[fight.boss_id][fight.difficulty] = player.boss_counts[fight.boss_id][fight.difficulty].to_i + 1
        player.save
        begin
          fpr = FightParseRecord.find_or_create_by(report_id: @report_id, fight_id: fight_id, player_id: player_hash['guid'].to_i, 
          )
          fpr.update_attributes(
            fight_guid: fight.id,
            player_name: player_hash['name'].to_s,
            actor_id: player_hash['id'].to_i,
            boss_id: fight.boss_id.to_i,
            difficulty: fight.difficulty.to_i,
            kill: fight.kill,
            class_type: player_hash['type'].to_s.capitalize
          )
        rescue ActiveRecord::RecordNotUnique
          retry
        end 
      end

      tries = 3
      begin
        Resque.logger.info("WCL API  /events/#{report_id}?start=#{fight_obj['start_time']}&end=#{fight_obj['start_time']}") unless Rails.env.development?
        response = HTTParty.get("https://www.warcraftlogs.com/v1/report/events/#{report_id}?start=#{fight_obj['start_time']}&end=#{fight_obj['start_time'].to_i + 500}&api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
        if response.code == 429
          raise RateLimitError
        else
          obj = JSON.parse(response.body)
          raise "no fights" if obj['events'].nil?
        end
      rescue RateLimitError
        Resque.logger.info("Hit rate limit, sleeping")
        Resque.logger.info(response.headers)
        Resque.logger.info(response.body)
        sleep(60)
        retry
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT, JSON::ParserError, SocketError
        if (tries -= 1) > 0
          retry
        end
      end
      next if obj.nil? || obj['events'].nil?
      # get combatant info
      obj['events'].each do |event|
        next if event['type'] != 'combatantinfo'
        player_hash = friendlies[event['sourceID']]
        next if player_hash.nil?
        player = Player.find_or_initialize_by(player_id: player_hash['guid'])
        spec = PlayerSpec.spec_name(event['specID'])
        player.specs << spec  unless player.specs.include? spec
        player.save
        fpr = FightParseRecord.find_by(report_id: @report_id, fight_id: fight_id, player_id: player_hash['guid'].to_i)
        fpr.update_attributes(spec: spec) unless fpr.nil?
      end
    end
    report.done!
    begin
      progress = Progress.find_by(model_type: 'Report', model_id: report_id)
      progress.destroy unless progress.nil?
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
      retry
    end
    begin
      Fail.where(model_type: 'Report', model_id: @report_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end

    Resque.logger.info("Report import finished (#{@report_id}). Total report time taken: #{Time.now - @started_at}")
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")

  rescue Resque::TermException
    begin
      Progress.where(model_type: 'Report', model_id: @report_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end
    Resque.enqueue(self, @report_id)
  rescue => e
    if !@retried
      # retry up to once time
      Resque.logger.info("Retrying Report #{@report_id} after error.")
      begin
        Progress.where(model_type: 'Report', model_id: @report_id).destroy_all
      rescue ActiveRecord::StaleObjectError
        retry
      end
      Resque.enqueue(self, @report_id, true)
    else
      raise e
    end
  end

  def self.after_perform(*args)
    ActiveRecord::Base.connection.disconnect!
  end

end