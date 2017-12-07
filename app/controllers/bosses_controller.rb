class BossesController < ApplicationController
  before_action :get_player
  before_action :extract_start_end_times, only: :show

  def show
    @boss_id = params[:boss_id].to_i
    @difficulty = params[:difficulty].to_i
    @boss_name = Boss.find(@boss_id).name rescue 'Unknown Boss'
    @tab = params[:tab]
    @page = params[:page] || 1
    @kill = params[:kill]
    @min_length = params[:min_length]
    @max_length = params[:max_length]
    @min_percent = params[:min_percent]
    @max_percent = params[:max_percent]
    fp_params = {report_id: @report_ids, player_id: @player_id, boss_id: @boss_id, difficulty: @difficulty}

    @spec = params[:spec] || FightParseRecord.where(fp_params).where("spec != '' and spec is not null").pluck(:spec).first || ''
    fp_params[:spec] = @spec
    
    @fpr_count = FightParseRecord.where(fp_params).count
    @processing_fp_ids = FightParseRecord.where(fp_params).where(status: [FightParseRecord.statuses[:processing], FightParseRecord.statuses[:queued]]).count
    
    fp_params[:kill] = params[:kill] unless params[:kill].blank?
    fp_params[:boss_percent] = (@min_percent.blank? ? 0 : @min_percent.to_i * 100)..(@max_percent.blank? ? 10000 : @max_percent.to_i * 100)
    unless params[:start_time].blank? || params[:end_time].blank?
      fp_params[:report_started_at] = params[:start_time]..params[:end_time]
      @daterange = "#{params[:start_time].strftime('%m/%d/%Y')} - #{params[:end_time].strftime('%m/%d/%Y')}" 
    end
    klass = Object.const_get("FightParse::#{@player.class_type.capitalize}::#{@spec.capitalize}") rescue FightParse
    @fresh_fp_ids = 0
    if klass.class == Class
      @fps = klass.where(fp_params).where("(ended_at - started_at) / 1000 between #{@min_length.blank? ? 0 : @min_length.to_i} and #{@max_length.blank? ? 6000 : @max_length.to_i}").order(report_started_at: :desc, started_at: :desc).page(@page).per(20)
      @fresh_fp_ids = @fpr_count - @fps.count - @processing_fp_ids
    else
      @fps = FightParse.none
    end

    @tab = params[:tab] || 'basic'
    display_helper = "DisplaySection::#{@player.class_type}::#{@spec}Display".constantize rescue false
    if display_helper
      # @sections = []
      # display_helper.sections[@tab].each do |section|
        @sections = DisplaySection.boss_data(@fps, @fps.map{|fp| display_helper.show_section(@tab, fp, true)})
        # @sections << section_data unless !section_data
      # end
      render template: 'bosses/show_data'
    else
      case params[:tab]
      when 'resources'
        if template_exists? File.join('bosses', @player.class_type.downcase, @spec.downcase, 'show_resources')
          render template: File.join('bosses', @player.class_type.downcase, @spec.downcase, 'show_resources')
        else
          render template: 'bosses/show_resources'
        end
      when 'cooldowns'
        if template_exists? File.join('bosses', @player.class_type.downcase, @spec.downcase, 'show_cooldowns')
          render template: File.join('bosses', @player.class_type.downcase, @spec.downcase, 'show_cooldowns')
        else
          render template: 'bosses/show_cooldowns'
        end
      else
        if template_exists? File.join('bosses', @player.class_type.downcase, @spec.downcase, 'show_basic')
          render template: File.join('bosses', @player.class_type.downcase, @spec.downcase, 'show_basic')
        else
          render template: 'bosses/show_basic'
        end
      end
    end
  end

  def batch_parse
    @boss_id = params[:boss_id].to_i
    @difficulty = params[:difficulty].to_i
    @spec = params[:spec]
    search_params = {report_id: @report_ids, 
                      player_id: @player_id, 
                      boss_id: @boss_id, 
                      difficulty: @difficulty}
    search_params[:spec] = @spec.capitalize unless @spec.nil?                  
    @fprs = FightParseRecord.where(search_params).to_a
    @fprs.each {|fpr| fpr.enqueue(true)}
    redirect_to action: :show and return
  end

  private
  def get_player
    @player_id = params[:player_id]
    @player = Player.find_by(player_id: @player_id)
    @report_ids = ReportPlayer.where(player_id: @player_id).pluck(:report_id)
  end

  def extract_start_end_times
    return unless params[:daterange].present?
    daterange = params.delete(:daterange)
    begin
      start_time, end_time = daterange.split(/\s*-\s*/).map {|date| Date.strptime(date, '%m/%d/%Y') }
      params.merge!(start_time: start_time, end_time: end_time)
    rescue ArgumentError
    end
  end
end