class ReportsController < ApplicationController
  before_filter :get_report
  protect_from_forgery :except => [:status, :fight_status, :load_fights]

  def show
    @report = Report.find_by(report_id: @report_id)
    if @report.nil?
      begin
        response = HTTParty.get("https://www.warcraftlogs.com:443/v1/report/fights/#{@report_id}?api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
        report_obj = JSON.parse(response.body)
        if !report_obj.has_key? 'fights'
          flash[:danger] = "Report not found (Was given '#{@report_id}' as the report ID)"
          redirect_to :root and return
        end
      rescue
        flash[:danger] = "There was an error performing the request. Please try again at a later time."
        redirect_to :root and return
      end
      begin
        @report = Report.find_or_create_by(report_id: @report_id)
      rescue ActiveRecord::RecordNotUnique
        retry
      end
      @report.queued!
      Resque.enqueue(Parser, @report_id)
    elsif @report.unprocessed?
      @report.queued!
      Resque.enqueue(Parser, @report_id)
    end
    player_ids = FightParseRecord.where(report_id: @report_id).order(:class_type).pluck(:player_id).uniq
    if player_ids.blank? and @report.done?
      redirect_to report_reload_path(report_id: @report_id) and return
    end
    @player_id = player_ids.include?(params[:player_id].to_i) ? params[:player_id].to_i : player_ids.first
    @players = Player.where(player_id: player_ids).order(:class_type).pluck(:player_id, :player_name, :class_type)
    @fight_list = {}
    FightParseRecord.where(report_id: @report_id, player_id: @player_id).includes(:fight).order(fight_id: :asc).each do |fpr|
      fight = fpr.fight
      next if fight.nil?
      @fight_list[fight.boss_id.to_s + fight.difficulty.to_s] ||= {name: "#{DifficultyType.label(fight.difficulty)} #{fight.name}", kills: [], wipes: []}
      fight.kill? ? @fight_list[fight.boss_id.to_s + fight.difficulty.to_s][:kills] << fpr : @fight_list[fight.boss_id.to_s + fight.difficulty.to_s][:wipes] << fpr
    end
    @boss_id = @fight_list.has_key?(params[:boss_id].to_i) ? params[:boss_id].to_i : @fight_list.keys.first
    @fp_ids = Hash[FightParseRecord.where(report_id: @report_id, status: [FightParseRecord.statuses[:queued], FightParseRecord.statuses[:processing]]).order(:class_type, :spec).map{|fp| [fp.id, fp]}]
    @progresses = Hash[Progress.where(model_type: 'FightParse', model_id: @fp_ids.map{|fp|fp[0]}).to_a.map{|p|[p.model_id, p]}]
    @queued = @fp_ids.reject{|id, fp| !fp.queued? }.size
    @processing = @fp_ids.reject{|id, fp| !fp.processing? }.size
  end

  def reload
    @report = Report.find_by(report_id: @report_id)
    if @report.nil?
      redirect_to :show and return
    end
    begin
      response = HTTParty.get("https://www.warcraftlogs.com:443/v1/report/fights/#{@report_id}?api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
      report_obj = JSON.parse(response.body)
      if !report_obj.has_key? 'fights'
        flash[:danger] = "Report not found (Was given '#{@report_id}' as the report ID)"
        redirect_to :root and return
      end
    rescue
      flash[:danger] = "There was an error performing the request. Please try again at a later time."
      redirect_to :root and return
    end
    unless @report.queued? || @report.processing?
      @report.queued!
      Resque.enqueue(Parser, @report_id)
    end
    
    redirect_to report_path(@report_id) and return

    respond_to do |format|
      format.js
    end
  end

  def show_player
    @player_id = params[:player_id]   

    fight = FightParseRecord.where(report_id: @report_id, player_id: @player_id).order(:fight_id).first
    if fight.nil?
      flash[:danger] = "Player not found"
        redirect_to :root and return
    end
    @fight_id = fight.fight_id
    redirect_to report_fight_parse_path(@report_id, @player_id, @fight_id) and return
  end

  def status
    @report = Report.find_by(report_id: @report_id)
    @progress = Progress.find_by(model_type: 'Report', model_id: @report_id)
    respond_to do |format|
      format.js
    end
  end

  def fight_status
    @report = Report.find_by(report_id: @report_id)
    @fp_ids = Hash[FightParseRecord.where(report_id: @report_id, status: [FightParseRecord.statuses[:queued], FightParseRecord.statuses[:processing]]).order(:class_type, :spec).map{|fpr| [fpr.id, fpr]}]
    fp_ids = params[:fp_ids].to_s.split('.')
    @fp_ids.merge! Hash[FightParseRecord.where(id: fp_ids).map{|fpr| [fpr.id, fpr]}]
    @progresses = Hash[Progress.where(model_type: 'FightParse', model_id: @fp_ids.keys).to_a.map{|p|[p.model_id, p]}]
    @queued = @fp_ids.reject{|id, fpr| !fpr.queued? }.size
    @processing = @fp_ids.reject{|id, fpr| !fpr.processing? }.size
    
    respond_to do |format|
      # format.html { redirect_to report_path(id: @report_id) and return }
      format.js
    end
  end

  def load_fights
    @report = Report.find_by(report_id: @report_id)
    @player_id = params[:player_id]
    @fight_list = {}
    FightParseRecord.where(report_id: @report_id, player_id: @player_id).includes(:fight).order(fight_id: :asc).each do |fp|
      @fight_list[fp.fight.boss_id.to_s + fp.fight.difficulty.to_s] ||= {name: "#{DifficultyType.label(fp.fight.difficulty)} #{fp.fight.name}", kills: [], wipes: []}
      fp.fight.kill? ? @fight_list[fp.fight.boss_id.to_s + fp.fight.difficulty.to_s][:kills] << fp : @fight_list[fp.fight.boss_id.to_s + fp.fight.difficulty.to_s][:wipes] << fp
    end
    @boss_id = @fight_list.has_key?(params[:boss_id].to_i) ? params[:boss_id].to_i : @fight_list.keys.first

    respond_to do |format|
      # format.html { redirect_to report_path(id: @report_id, player_id: @player_id) and return }
      format.js
    end
  end

  def batch
    @player_id = params[:player_id]
    @player = Player.find_by(player_id: @player_id)
    @report_id = params[:report_id]
    search_params = {player_id: @player_id, report_id: @report_id}
    search_params[:kill] = true if params[:kills]
    @fprs = FightParseRecord.where(search_params).to_a
    @fprs.each do |fpr|
      fpr.enqueue
    end
    redirect_to report_path(id: @report_id, player_id: @player_id) and return
  end

  private

  def get_report
    @report_id = (params[:report_id] || params[:id]).gsub(/[^0-9A-Za-z.\-]/, '?')
  end
end
