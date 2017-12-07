require 'resque/errors'
class GuildParser
  include Resque::Plugins::UniqueJob
  @queue = :guild
  @guild_id = 0
  @retried = false
  @started_at = 0

  def self.on_failure_reset(e, *args)
    guild = Guild.find(@guild_id) rescue nil
    if !guild.nil?
      guild.failed! 
      begin
        failure = Fail.find_or_create_by(model_type: 'Guild', model_id: @guild_id)
        failure.update_attributes(status: 'failed')
      rescue ActiveRecord::StaleObjectError
        retry
      end
    end
    Resque.logger.error("Error. Guild #{@guild_id}")
    Resque.logger.error(e)
    Resque.logger.error(e.backtrace[0]) unless e.backtrace.nil?
    Rollbar.error(e, "Guild Parser error", guild_id: @guild_id, :use_exception_level_filters => true)
  end

  def self.perform(guild_id, retried=false)
    return false if guild_id.to_i == 0
    @retried = retried
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")
    @guild_id = guild_id.to_i
    @started_at = Time.now
    guild = Guild.find(guild_id)
    guild.processing!
    # import the reports
    tries = 3
    begin
      Resque.logger.info("WCL API  /reports/guild/#{URI.escape(guild.name)}/#{URI.escape(guild.server_slug)}/#{URI.escape(guild.region)}?start=#{guild.last_import}")
      response = HTTParty.get("https://www.warcraftlogs.com:443/v1/reports/guild/#{URI.escape(guild.name)}/#{URI.escape(guild.server_slug)}/#{URI.escape(guild.region)}?start=#{guild.last_import}&api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
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
    if (report_obj.nil? || report_obj.is_a?(Hash)) && @retried
      guild.empty!
      begin
        failure = Fail.find_or_create_by(model_type: 'Guild', model_id: @guild_id)
        failure.update_attributes(status: 'empty')
      rescue ActiveRecord::StaleObjectError
        retry
      end
      return
    end
    guild.update_attributes(last_import: report_obj.last['start'].to_i) unless report_obj.nil? || report_obj.size == 0
    report_obj.reverse_each do |obj|
      begin
        report = Report.find_or_create_by(report_id: obj['id'])
      rescue ActiveRecord::RecordNotUnique
        retry
      end
      report.update_attributes(title: obj['title'], started_at: Time.at(obj['start'] / 1000), ended_at: Time.at(obj['end'] / 1000), zone: obj['zone'])
      begin
        GuildReport.find_or_create_by(guild_id: guild.id, report_id: report.id)
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
    guild.done!
    begin
      Fail.where(model_type: 'Guild', model_id: @guild_id).destroy_all
    rescue ActiveRecord::StaleObjectError
      retry
    end

    Resque.logger.info("Guild import finished (#{@guild_id}). Total report time taken: #{Time.now - @started_at}")
    Resque.logger.info("Queue Sizes: parse=#{Resque.size(:parse)} killcache=#{Resque.size(:cache_kill)} cache=#{Resque.size(:cache)} single_parse=#{Resque.size(:single_parse)} batch_parse=#{Resque.size(:batch_parse)} working=#{Resque.working.size} total=#{Resque.working.size + Resque.size(:parse) + Resque.size(:cache_kill) + Resque.size(:cache) + Resque.size(:single_parse) + Resque.size(:batch_parse)}")

  rescue Resque::TermException
    Resque.enqueue(self, @guild_id)
  rescue => e
    if !@retried
      # retry up to once time
      Resque.logger.info("Retrying Guild #{@guild_id} after error.")
      Resque.enqueue(self, @guild_id, true)
    else
      raise e
    end
  end

  def self.after_perform(*args)
    ActiveRecord::Base.connection.disconnect!
  end

end