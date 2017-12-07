class FixFpExpansion < ActiveRecord::Migration
  def change
    ids = Report.where("started_at >= '2016-07-19'::date").pluck(:report_id)
    FightParse.where(report_id: ids, expansion: 6.2).each do |fp|
      fp.update_attributes(expansion: 7.0)
    end
  end
end
