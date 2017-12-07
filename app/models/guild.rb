class Guild < ActiveRecord::Base
  has_many :guild_reports
  has_many :reports, through: :guild_reports
  enum status: [:unprocessed, :processing, :done, :failed, :empty, :queued]
end