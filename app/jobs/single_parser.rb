require 'resque/errors'
require 'zip'
class SingleParser
  include Resque::Plugins::UniqueJob
  @queue = :single_parse
  @fpr_id = 0
  @retried = false
  @started_at = 0

  def self.on_failure_reset(e, *args)
    fpr = FightParseRecord.find(@fpr_id) rescue nil
    if !fpr.nil?
      fpr.failed! 
      begin
        failure = Fail.find_or_create_by(model_type: 'FightParse', model_id: @fpr_id)
        failure.update_attributes(status: 'failed')
      rescue ActiveRecord::StaleObjectError
        retry
      end
    end
    begin
      Progress.where(model_type: 'FightParse', model_id: @fpr_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end
    Resque.logger.error("Fight Parse error. #{@fpr_id}")
    Resque.logger.error(e)
    Resque.logger.error(e.backtrace.join("\n")) unless e.backtrace.nil?
    Rollbar.error(e, "Fight Parse error", fp_id: @fpr_id, :use_exception_level_filters => true)
  end

  def self.perform(fpr_id, retried=false)
    return false if fpr_id.to_i == 0
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")
    @fpr_id = fpr_id.to_i
    @retried = retried
    @started_at = Time.now
    return false if @fpr_id == 0
    fpr = FightParseRecord.find_by_id(@fpr_id)
    return false if fpr.nil?
    return false if !fpr.parsable?
    fight = fpr.fight
    actors = {nil => {guid: nil, name: 'Environment'}}
    pets = []

    tries = 3
    begin
      Resque.logger.info("WCL API  /fights/#{fpr.report_id}") unless Rails.env.development?
      response = HTTParty.get("https://www.warcraftlogs.com/v1/report/fights/#{fpr.report_id}?api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
      if response.code == 429
        raise RateLimitError
      else
        report_obj = JSON.parse(response.body)
        report_obj['friendlies'].each do |a|
          actors[a['id']] = {guid: a['guid'], name: a['name'], player: true}
        end
        report_obj['enemies'].each do |a|
          actors[a['id']] = {guid: a['guid'], name: a['name']}
        end
        report_obj['friendlyPets'].each do |a|
          actors[a['id']] = {guid: a['guid'], name: a['name']}
          pets << a['id'] if a['petOwner'] == fpr.actor_id
        end
        report_obj['enemyPets'].each do |a|
          actors[a['id']] = {guid: a['guid'], name: a['name']}
        end
      end
    rescue RateLimitError
      Resque.logger.info("Hit rate limit, sleeping")
      Resque.logger.info(response.headers)
      Resque.logger.info(response.inspect)
      sleep(60)
      retry
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT, JSON::ParserError, NoMethodError, SocketError
      if (tries -= 1) > 0
        retry
      end
    end

    tries = 3
    begin
      Resque.logger.info("WCL API  /events/#{fpr.report_id}?start=#{fight.started_at}&end=#{fight.ended_at}&actorid=#{fpr.actor_id}") unless Rails.env.development?
      response = HTTParty.get("https://www.warcraftlogs.com/v1/report/events/#{fpr.report_id}?start=#{fight.started_at}&end=#{fight.ended_at}&actorid=#{fpr.actor_id}&api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
      if response.code == 429
        raise RateLimitError
      else
        obj = JSON.parse(response.body)
        events = obj['events']
        cursor = obj['nextPageTimestamp']
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

    if events.nil? && @retried
      fpr.empty!
      begin
        failure = Fail.find_or_create_by(model_type: 'FightParse', model_id: @fpr_id)
        failure.update_attributes(status: 'empty')
      rescue ActiveRecord::StaleObjectError
        retry
      end
      begin
        Progress.where(model_type: 'FightParse', model_id: @fpr_id).destroy_all
      rescue ActiveRecord::StaleObjectError
        retry
      end
      return
    end

    spec = ''
    events.each do |event|
      if event['type'] == 'combatantinfo'
        spec = PlayerSpec.spec_name(event['specID'])
        break
      end
    end

    klass = Object.const_get("FightParse::#{fpr.class_type.capitalize}::#{spec.capitalize}") rescue FightParse
    fp = klass.find_or_create_by(report_id: fpr.report_id, fight_id: fpr.fight_id, player_id: fpr.player_id)
    fpr.processing!
    fp.processing!
    
    events.each do |event|
      if event['type'] == 'combatantinfo'
        fp.spec = PlayerSpec.spec_name(event['specID'])
        fp.combatant_info = event
        player = Player.find_by(player_id: fp.player_id)
        if !player.specs.include?(fp.spec)
          player.specs << fp.spec
          player.save
        end
        break
      end
    end
    fp.assign_attributes(actor_id: fpr.actor_id,
                        player_name: fpr.player_name,
                        class_type: fpr.class_type,
                        zone_id: fight.zone_id,
                        boss_id: fight.boss_id, 
                        boss_name: fight.name,
                        boss_percent: fight.boss_percent,
                        difficulty: fight.difficulty,
                        kill: fight.kill,
                        report_started_at: fight.report_started_at,
                        started_at: fight.started_at,
                        ended_at: fight.ended_at)   
    begin
      progress = Progress.find_or_create_by(model_type: 'FightParse', model_id: fpr.id)
      progress.update_attributes(current: 1, finish: fight.ended_at - fight.started_at)
    rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
      retry
    end

    fp.cooldown_parses.destroy_all
    fp.buff_parses.destroy_all
    fp.debuff_parses.destroy_all
    fp.external_cooldown_parses.destroy_all
    fp.external_buff_parses.destroy_all
    fp.kpi_parses.destroy_all
    fp.init_vars
    fp.set_actors(actors)
    fp.init_pets(pets)

    loop do
      break if events == []
      events.each do |event|
        handled = false
        # next if event['timestamp'] + 1 < cursor # ignore past events coming at weird times
        if event['sourceID'] == fp.actor_id # the player did something
          fp.handle_my_event(event)
          handled = true
        end
        if pets.include?(event['sourceID']) # the player's pet did something
          fp.handle_pet_event(event)
          handled = true
        end
        if event['targetID'] == fp.actor_id && (event['type'] == 'damage' || event['sourceID'] != fp.actor_id)
          # something was done to the player. damaging yourself should be recorded
          fp.handle_receive_event(event)
          handled = true
        end
        if pets.include?(event['targetID']) && !pets.include?(event['sourceID']) # something was done to the player's pet
          fp.handle_receive_pet_event(event)
          handled = true
        end
        if !handled # mostly used for tracking healers' damage reduction
          fp.handle_external_event(event)
        end
      end
      
      break if cursor.nil?

      begin
        progress = Progress.find_or_create_by(model_type: 'FightParse', model_id: fp.id)
        progress.update_attributes(current: cursor - fight.started_at)
      rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
        retry
      end

      tries = 3
      begin
        Resque.logger.info("WCL API (continue) /events/#{fp.report_id}?start=#{cursor}&end=#{fight.ended_at}&actorid=#{fp.actor_id}") unless Rails.env.development?
        response = HTTParty.get("https://www.warcraftlogs.com/v1/report/events/#{fp.report_id}?start=#{cursor}&end=#{fight.ended_at}&actorid=#{fp.actor_id}&api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
        if response.code == 429
          raise RateLimitError
        else
          obj = JSON.parse(response.body)
          events = obj['events']
          cursor = obj['nextPageTimestamp']
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
      if events.nil? && @retried
        fp.empty! # mostly so we can try again later
        begin
          failure = Fail.find_or_create_by(model_type: 'FightParse', model_id: @fpr_id)
          failure.update_attributes(status: 'empty')
        rescue ActiveRecord::StaleObjectError
          retry
        end
        begin
          Progress.where(model_type: 'FightParse', model_id: @fpr_id).destroy_all
        rescue ActiveRecord::StaleObjectError
          retry
        end
        return
      end
    end

    if fp.is_a?(HealerParse)
      if !fight.queued? && !fight.processing? && (!fight.done? || fight.updated_at < Time.now - 6.months)
        fight.queue_healing_parses
      end
    end

    fp.clean
    fp.status = FightParseRecord.statuses[:done]
    fp.save
    FightParseRecord.find_by(report_id: fp.report_id, fight_id: fp.fight_id, player_id: fp.player_id).update_attributes(parsed_at: fp.updated_at, status: FightParseRecord.statuses[:done], version: fp.version)
    begin
      progress = Progress.find_by(model_type: 'FightParse', model_id: fpr.id)
      progress.destroy unless progress.nil?
    rescue ActiveRecord::StaleObjectError
      retry
    end
    begin
      Fail.where(model_type: 'FightParse', model_id: fpr.id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end

    Resque.logger.info("Fight Parse finished #{@fpr_id}. Total FP time taken: #{Time.now - @started_at}")
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")
    
  rescue Resque::TermException
    begin
      Progress.where(model_type: 'FightParse', model_id: @fpr_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end
    Resque.enqueue(self, @fpr_id)
  rescue => e
    if !@retried
      # retry up to once time
      Resque.logger.info("Retrying Fight Parse #{@fpr_id} after error.")
      begin
        Progress.where(model_type: 'FightParse', model_id: @fpr_id).destroy_all
      rescue ActiveRecord::StaleObjectError
        retry
      end
      Resque.enqueue(self, @fpr_id, true)
    else
      raise e
    end
  end

  def self.after_perform(*args)
    ActiveRecord::Base.connection.disconnect!
  end

end