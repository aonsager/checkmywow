class KpiParse < ActiveRecord::Base
  belongs_to :fight_parse
  serialize :kpi_hash, Hash
  serialize :details_hash, Hash

end