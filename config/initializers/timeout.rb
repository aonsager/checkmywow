if Rails.env.production?
  Rack::Timeout.timeout = 20 # seconds
  Rack::Timeout::Logger.logger = Logger.new(STDOUT)
  Rack::Timeout::Logger.logger.level = Logger::ERROR
end