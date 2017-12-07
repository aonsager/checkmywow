class ReportPlayer < ActiveRecord::Base
  belongs_to :report
  belongs_to :player
end