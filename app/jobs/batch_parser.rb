require 'resque/errors'
class BatchParser < SingleParser
  include Resque::Plugins::UniqueJob
  @queue = :batch_parse
  
end