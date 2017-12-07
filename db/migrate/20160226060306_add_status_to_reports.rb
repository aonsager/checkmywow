class AddStatusToReports < ActiveRecord::Migration
  def change
    add_column :reports, :status, :integer, :default => 0
    Report.where(imported: true).each do |report|
      report.update_attributes(status: 2)
    end
  end
end
