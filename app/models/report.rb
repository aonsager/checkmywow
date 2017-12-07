class Report < ActiveRecord::Base
  has_many :fights, primary_key: 'report_id', dependent: :destroy
  has_many :fight_parse_records, primary_key: 'report_id', dependent: :destroy
  has_many :fight_parses, primary_key: 'report_id', dependent: :destroy
  has_many :guild_reports
  has_many :report_players
  has_many :guilds, through: :guild_reports
  has_many :players, through: :report_players
  enum status: [:unprocessed, :processing, :done, :failed, :empty, :queued]

  def fights_for_select
    return Fight.where(report_id: self.report_id).order(:id).map{|f| f.done? ? [f.full_name, f.fight_id] : ["--#{f.full_name}--", nil]}
  end
end