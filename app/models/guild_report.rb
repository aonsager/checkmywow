class GuildReport < ActiveRecord::Base
  belongs_to :guild
  belongs_to :report
end