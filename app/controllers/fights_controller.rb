class FightsController < ApplicationController

  def show
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    @report = Report.find_by(report_id: report_id)
    @fight = Fight.find_by(report_id: report_id, fight_id: fight_id)
    if @fight.nil? || @report.nil?
      flash[:danger] = "Fight not found"
      redirect_to :root
      return 
    end
    @fps = FightParseRecord.where(report_id: report_id, fight_id: fight_id).order(:class_type, :spec).to_a
    @progresses = Hash[Progress.where(model_type: 'FightParse', model_id: @fps.map{|fp|fp.id}).to_a.map{|p|[p.model_id, p]}]
    @queued = @fps.map{|fp| fp.queued? ? fp.status : nil}.compact.size
    @processing = @fps.map{|fp| fp.processing? ? fp.status : nil}.compact.size
  end

  def status
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    @report = Report.find_by(report_id: report_id)
    @fight = Fight.find_by(report_id: report_id, fight_id: fight_id)
    @fps = FightParseRecord.where(report_id: report_id, fight_id: fight_id).order(:class_type, :spec).to_a
    @progresses = Hash[Progress.where(model_type: 'FightParse', model_id: @fps.map{|fp|fp.id}).to_a.map{|p|[p.model_id, p]}]
    @queued = @fps.map{|fp| fp.queued? ? fp.id : nil}.compact.size
    @processing = @fps.map{|fp| fp.processing? ? fp.id : nil}.compact.size

    respond_to do |format|
      format.js
    end
  end

end
