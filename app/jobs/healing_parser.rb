
require 'resque/errors'
class HealingParser
  include Resque::Plugins::UniqueJob
  @queue = :healing_parse
  @fight_id = 0
  @player_id = 0
  @retried = false
  @started_at = 0

  def self.on_failure_reset(e, *args)
    fight = Fight.find_by_id(@fight_id)
    if !fight.nil?
      fight.failed! 
      begin
        failure = Fail.find_or_create_by(model_type: 'Fight', model_id: @fight_id)
        failure.update_attributes(status: 'failed')
      rescue ActiveRecord::StaleObjectError
        retry
      end
    end
    Resque.logger.error("Healing Parse error. #{@fight_id}-#{@player_id}")
    Resque.logger.error(e)
    Resque.logger.error(e.backtrace[0]) unless e.backtrace.nil?
    Rollbar.error(e, "Healing Parse error", fight_id: @fight_id, player_id: @player_id, :use_exception_level_filters => true)
  end

  def self.perform(fight_id, player_id, retried=false)
    return false if fight_id.to_i == 0 || player_id.to_i == 0
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")
    @fight_id = fight_id.to_i
    @player_id = player_id.to_i
    @retried = retried
    @started_at = Time.now


    fight = Fight.find(@fight_id)
    HealingParse.where(report_id: fight.report_id, target_id: @player_id, fight_id: fight.fight_id).destroy_all
    actors = {nil => {guid: nil, name: 'Environment'}}
    pets = []

    tries = 3
    begin
      Resque.logger.info("WCL API  /fights/#{fight.report_id}") unless Rails.env.development?
      response = HTTParty.get("https://www.warcraftlogs.com/v1/report/fights/#{fight.report_id}?api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
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
        end
        report_obj['enemyPets'].each do |a|
          actors[a['id']] = {guid: a['guid'], name: a['name']}
        end
      end
    rescue RateLimitError
      Resque.logger.info("Hit rate limit, sleeping")
      Resque.logger.info(response.headers)
      Resque.logger.info(response.body)
      sleep(60)
      retry
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT, JSON::ParserError, NoMethodError, SocketError
      if (tries -= 1) > 0
        retry
      end
    end
    
    # collect low hp periods
    cursor = fight.started_at
    tries = 3
    begin
      query = "target.disposition = 'friendly' AND target.type = 'player' AND target.id = '#{@player_id}' AND ((resources.maxHitPoints > 0 AND 100 * rawHealing / resources.maxHitPoints > 10) OR type = 'death' OR ((type = 'absorbed' OR type = 'heal' OR type = 'damage') AND resources.hpPercent < 60))"
      Resque.logger.info("WCL API  /events/#{fight.report_id}?start=#{cursor}&end=#{fight.ended_at}&filter=#{URI.escape(query)}") unless Rails.env.development?
      response = HTTParty.get("https://www.warcraftlogs.com/v1/report/events/#{fight.report_id}?start=#{cursor}&end=#{fight.ended_at}&filter=#{URI.escape(query)}&api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
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

    @hp_parses = {}

    loop do
      if events.nil? && @retried
        fight.empty!
        begin
          failure = Fail.find_or_create_by(model_type: 'Fight', model_id: @fight_id)
          failure.update_attributes(status: 'empty')
        rescue ActiveRecord::StaleObjectError
          retry
        end
        begin
          Progress.where(model_type: 'Fight', model_id: @fight_id).destroy_all
        rescue ActiveRecord::StaleObjectError
          retry
        end
        return
      end
      events.each do |event|
        ability_name = event['ability']['name'] rescue nil
        event.has_key?('target') ? target_id = event['target']['id'] : target_id = event['targetID']
        next unless actors.has_key?(target_id) && actors[target_id][:player]
        target_name = actors[target_id][:name]
        time = (event['timestamp'] - fight.started_at)
        key = "hp-#{target_name}"
        if !@hp_parses.has_key?(key) || !@hp_parses[key][:active] || event['timestamp'] - @hp_parses[key][:hp].ended_at > 10000
          if event['hitPoints'].to_i > 0 && event['maxHitPoints'].to_i > 0 && (100 * event['hitPoints'].to_i) / event['maxHitPoints'].to_i < 30
            # set up a new cooldown parse for this low-hp period
            @hp_parses[key] ||= {hp: nil, buffer: 0, active: false}
            if !@hp_parses[key][:hp].nil?
              @hp_parses[key][:hp].save
              @hp_parses[key][:active] = false
            end
            @hp_parses[key][:hp] = HealingParse.new(report_id: fight.report_id, fight_id: fight.fight_id, target_id: @player_id, target_name: target_name, kpi_hash: {damage_received: 0, healing_received: 0, healing_by_player: {}, death: false}, started_at: event['timestamp'], ended_at: event['timestamp'])
            @hp_parses[key][:hp].details_hash[:events] = []
            @hp_parses[key][:active] = true
          end
        end
        if @hp_parses.has_key?(key) && @hp_parses[key][:active]
          if event['type'] == 'damage'
            @hp_parses[key][:hp].kpi_hash[:damage_received] += event['amount'].to_i
            hp = (event['hitPoints'].to_i == 0 || event['maxHitPoints'].to_i == 0) ? @hp_parses[key][:hp].details_hash[:events].last[:hp] : 100 * event['hitPoints'].to_i / event['maxHitPoints'].to_i
            @hp_parses[key][:hp].details_hash[:events] << {timestamp: event['timestamp'], source: actors[event['sourceID']][:name], name: ability_name, type: 'damage', amount: event['amount'].to_i, hp: hp}
            @hp_parses[key][:hp].ended_at = event['timestamp']
          elsif event['type'] == 'heal'
            @hp_parses[key][:hp].kpi_hash[:healing_received] += event['amount'].to_i
            @hp_parses[key][:hp].kpi_hash[:healing_by_player][actors[event['sourceID']][:name]] = @hp_parses[key][:hp].kpi_hash[:healing_by_player][event['sourceID']].to_i + event['amount'].to_i
            hp = (event['hitPoints'].to_i == 0 || event['maxHitPoints'].to_i == 0) ? @hp_parses[key][:hp].details_hash[:events].last[:hp] : 100 * event['hitPoints'].to_i / event['maxHitPoints'].to_i
            @hp_parses[key][:hp].details_hash[:events] << {timestamp: event['timestamp'], source: actors[event['sourceID']][:name], name: ability_name, type: 'heal', amount: event['amount'].to_i, hp: hp}
            @hp_parses[key][:hp].ended_at = event['timestamp']
            if (event['maxHitPoints'].to_i > 0) && (100 * event['hitPoints'].to_i / event['maxHitPoints'].to_i) > 50
              @hp_parses[key][:hp].ended_at = event['timestamp']
              @hp_parses[key][:hp].save
              @hp_parses[key][:active] = false
            end
          elsif event['type'] == 'absorbed'
            @hp_parses[key][:hp].kpi_hash[:healing_received] += event['amount'].to_i
            @hp_parses[key][:hp].kpi_hash[:healing_by_player][actors[event['sourceID']][:name]] = @hp_parses[key][:hp].kpi_hash[:healing_by_player][event['sourceID']].to_i + event['amount'].to_i
            @hp_parses[key][:hp].details_hash[:events] << {timestamp: event['timestamp'], source: actors[event['sourceID']][:name], name: ability_name, type: 'absorb', amount: event['amount'].to_i, hp: @hp_parses[key][:hp].details_hash[:events].last[:hp]}
            @hp_parses[key][:hp].ended_at = event['timestamp']
          elsif event['type'] == 'death'
            @hp_parses[key][:hp].kpi_hash[:death] = true
            @hp_parses[key][:hp].details_hash[:events] << {timestamp: event['timestamp'], type: 'death'}
            @hp_parses[key][:hp].ended_at = event['timestamp']
            @hp_parses[key][:hp].save
            @hp_parses[key][:active] = false
          end
        end
      end

      break if cursor.nil?

      tries = 3
      begin
        query = "target.disposition = 'friendly' AND target.type = 'player' AND target.id = '#{@player_id}' AND ((resources.maxHitPoints > 0 AND 100 * rawHealing / resources.maxHitPoints > 10) OR type = 'death' OR ((type = 'absorbed' OR type = 'heal' OR type = 'damage') AND resources.hpPercent < 60))"
        Resque.logger.info("WCL API  /events/#{fight.report_id}?start=#{cursor}&end=#{fight.ended_at}&filter=#{URI.escape(query)}") unless Rails.env.development?
        response = HTTParty.get("https://www.warcraftlogs.com/v1/report/events/#{fight.report_id}?start=#{cursor}&end=#{fight.ended_at}&filter=#{URI.escape(query)}&api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
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
    end
    
    # Update the progress, check if all healing parses are done
    begin
      progress = Progress.find_by(model_type: 'Fight', model_id: @fight_id)
      unless progress.nil?
        progress.current += 1
        progress.save
      end
    rescue ActiveRecord::StaleObjectError
      retry
    end
    if !progress.nil? && progress.current == progress.finish
      fight.done!
      progress.destroy
    end
    begin
      Fail.where(model_type: 'Fight', model_id: @fight_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end
    
    Resque.logger.info("Healing Parse finished #{@fight_id}. Total time taken: #{Time.now - @started_at}")
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")
    
  rescue Resque::TermException
    Resque.enqueue(self, @fight_id, @player_id)
  rescue => e
    if !@retried
      # retry up to once time
      Resque.logger.info("Retrying Healing Parse #{@fight_id}-#{@player_id} after error.")
      Resque.enqueue(self, @fight_id, @player_id, true)
    else
      raise e
    end
  end

  def self.after_perform(*args)
    ActiveRecord::Base.connection.disconnect!
  end

end