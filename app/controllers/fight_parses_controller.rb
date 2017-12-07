class FightParsesController < ApplicationController
  protect_from_forgery :except => [:status, :load_hp_graph, :load_class_graph, :load_casts_table]
  before_action :find_fight_parse_record, :except => [:status, :load_hp_graph]
  before_action :validate_fp, :only => [:show, :compare]

  def show
    @tab = params[:tab] ||= 'basic'
    display_helper = "DisplaySection::#{@fp.class_type}::#{@fp.spec}Display".constantize rescue false
    if display_helper
      @sections = display_helper.show_section(@tab, @fp)
      if @sections.nil?
        @tab = 'basic'
        @sections = display_helper.show_section(@tab, @fp) 
      end
      render template: 'fight_parses/show_data'
    else
      @cooldowns = {'cd' => {}, 'pet' => {}, 'proc' => {}, 'potion' => {}, 'heal' => {}, 'absorb' => {}}
      @fp.cooldown_parses.order(started_at: :asc).each do |cd|
        @cooldowns[cd.cd_type][cd.name] ||= []
        @cooldowns[cd.cd_type][cd.name] << cd
      end
      @external_cooldowns = {'absorb' => {}, 'cd' => {}, 'hp' => {}}
      @fp.external_cooldown_parses.order(started_at: :asc).each do |cd|
        @external_cooldowns[cd.cd_type][cd.name] ||= []
        @external_cooldowns[cd.cd_type][cd.name] << cd
      end
      @buffs = {}
      @fp.buff_parses.order(created_at: :asc).each do |bp|
        @buffs[bp.name] ||= []
        @buffs[bp.name] << bp
      end
      @debuffs = {}
      @fp.debuff_parses.order(created_at: :asc).each do |db|
        @debuffs[db.name] ||= []
        @debuffs[db.name] << db
      end
      @external_buffs = {}
      @fp.external_buff_parses.order(created_at: :asc).each do |bp|
        @external_buffs[bp.name] ||= []
        @external_buffs[bp.name] << bp
      end
      @kpi_parses = {}
      @fp.kpi_parses.each do |kpi|
        @kpi_parses[kpi.name] = kpi
      end
      
      case @tab
      when 'casts'
        if !@fp.spec.blank? && template_exists?(File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_casts'))
          render template: File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_casts')
        else
          render template: 'fight_parses/show_casts'
        end
      when 'resources'
        if !@fp.spec.blank? && template_exists?(File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_resources'))
          render template: File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_resources')
        else
          render template: 'fight_parses/show_resources'
        end
      when 'cooldowns'
        if !@fp.spec.blank? && template_exists?(File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_cooldowns'))
          render template: File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_cooldowns')
        else
          render template: 'fight_parses/show_cooldowns'
        end
      when 'hp'
        render template: 'fight_parses/show_hp'
      when 'raid_hp'
        if @fp.is_a?(HealerParse) 
          @healing_parses = HealingParse.where(report_id: @fp.report_id, fight_id: @fp.fight_id).order(:started_at).to_a
          render template: 'fight_parses/show_raid_hp'
        else
          if !@fp.spec.blank? && template_exists?(File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_basic'))
            render template: File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_basic')
          else
            render template: 'fight_parses/show_basic'
          end
        end
      else
        if !@fp.spec.blank? && template_exists?(File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_basic'))
          render template: File.join('fight_parses', @fp.class_type.downcase, @fp.spec.downcase, 'show_basic')
        else
          render template: 'fight_parses/show_basic'
        end
      end
    end
  end

  def compare
    if @fp.nil? || @fp.spec.nil?
      flash[:danger] = "Unable to detect spec. No comparison available."
      redirect_to action: 'show' and return
    end
    begin
      @filterrific = initialize_filterrific(
        @fp.class,
        params[:filterrific],
        persistence_id: false,
        default_filter_params: {
          kill: true,
          boss: @fp.boss_id,
          sorted_by: 'casts_score_desc',
          difficulty: @fp.difficulty,
          fight_length: {length: @fp.fight_time, range: 0},
        },
        select_options: { 
          talents: [['Same Talents', @fp.talents]],
          difficulty: [["#{DifficultyType.label(@fp.difficulty)} only", @fp.difficulty]],
        },
      ) or return
      @other_fps = @filterrific.find.limit(20)
    rescue NoMethodError
      @filterrific = nil
      @other_fps = nil
    end
    
    # get list of my other fights
    @report_ids = ReportPlayer.where(player_id: @fp.player_id).pluck(:report_id)
    @my_fprs = FightParseRecord.where(report_id: @report_ids, player_id: @fp.player_id, boss_id: @fp.boss_id, difficulty: @fp.difficulty).pluck(:status)

    respond_to do |format|
      format.html
      format.js
    end

  rescue ActiveRecord::RecordNotFound => e
    # There is an issue with the persisted param_set. Reset it.
    redirect_to(reset_filterrific_url(format: :html)) and return
  end

  def changelog
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    player_id = params[:player_id]
    @fight = Fight.find_by(report_id: report_id, fight_id: fight_id)
    @report = Report.find_by(report_id: report_id)
    if @fight.nil? || @report.nil?
      flash[:danger] = "Fight not found."
      redirect_to :root
      return 
    end
    @fp = @fpr.find_fp
    if @fp.nil?
      redirect_to action: 'show' and return
    end
    @not_latest = true if @fp.version < @fp.class.latest_version || @fp.hotfix < @fp.class.latest_hotfix
    fp_types = ['FightParse', "#{@fp.spec} #{@fp.class_type}"]
    fp_types << 'HealerParse' if @fp.is_a?(HealerParse)
    fp_types << 'TankParse' if @fp.is_a?(TankParse)
    changelogs = Changelog.where(fp_type: fp_types).order(created_at: :desc)
    @changelogs = {}
    changelogs.each do |changelog|
      patch = changelog.patch ? "Patch #{changelog.patch}" : 'Older Versions'
      @changelogs[patch] ||= []
      @changelogs[patch] << changelog
    end
    
    render template: 'fight_parses/not_latest'
  end

  def single_parse
    @report_id = params[:report_id]
    fight_id = params[:fight_id]
    player_id = params[:player_id]
    @btn_id = params[:btn_id]
    @fight = Fight.find_by(report_id: @report_id, fight_id: fight_id)
    @report = Report.find_by(report_id: @report_id)
    if @fight.nil? || @report.nil?
      flash[:danger] = "Fight not found"
      redirect_to :root
      return 
    end
    @fpr.enqueue
    if !request.xhr?
      redirect_to action: :show and return
    end

    respond_to do |format|
      format.js 
    end
  end

  def load_hp_graph
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    @player_id = params[:player_id]
    @fight = Fight.find_by(report_id: report_id, fight_id: fight_id)
    @hp_parses = {}
    file = S3_BUCKET.object("hp/#{report_id}_#{fight_id}_#{@player_id}.json")
    if file.exists?
      @hp_parses[@player_id] = JSON.parse(file.get.body.string)
      @hp_parses[@player_id]['base_hp'] = []
      @hp_parses[@player_id]['hp'].each_with_index do |hash, index|
        @hp_parses[@player_id]['base_hp'][index] = [hash[0], hash[1] - @hp_parses[@player_id]['self_heal'][index][1] - @hp_parses[@player_id]['external_heal'][index][1] - @hp_parses[@player_id]['mitigated'][index][1]]
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def load_class_graph
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    @player_id = params[:player_id]
    @graph_type = params[:graph_type]
    @fp = @fpr.find_fp
    @graphs = {}
    file = S3_BUCKET.object("#{@fp.spec.downcase}/#{@graph_type}_#{report_id}_#{fight_id}_#{@player_id}.json")
    if file.exists?
      @graphs = JSON.parse(file.get.body.string)
    end

    respond_to do |format|
      format.js
    end
  end

  def load_casts_table
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    @player_id = params[:player_id]
    @ability = params[:ability]
    @fp = @fpr.find_fp
    file = S3_BUCKET.object("casts_details/#{report_id}_#{fight_id}_#{@player_id}.json")
    if file.exists?
      @casts_details = JSON.parse(file.get.body.string)
      @casts = []
      last_cast = 0
      off_cd = nil
      buff = true
      begin_cast = false
      @cds = {}
      @fp.track_casts.each do |spell, hash|
        @cds[spell] = {
          cd: hash[:cd].to_i,
          max_delay: ((@fp.fight_time - @fp.effective_cd(hash) * (@fp.casts_possible(hash).to_i - 1)) / @fp.casts_possible(hash).to_i rescue 0),
        }
        @cds[spell][:effective_cd] = @fp.effective_cd(hash) if hash.has_key?(:reduction) || hash.has_key?(:extra)
      end
      @casts_details.each do |cast|
        if cast['ability'] != @ability && off_cd.to_i == 0
          @casts.last['spacer'] = true if @casts.count > 0
          next
        elsif cast['ability'] == @ability
          if cast['type'] == 'off_cd'
            off_cd = cast['timestamp']
          elsif cast['type'] == 'begin_cast'
            begin_cast = true
            if off_cd == 0 || cast['timestamp'] - (off_cd || @fp.started_at) <= @cds[@ability][:max_delay] * 1000
              cast['class'] = 'green'
            elsif cast['timestamp'] - (off_cd || @fp.started_at) <= @cds[@ability][:cd] * 1000
              cast['class'] = 'yellow'
            else
              cast['class'] = 'red'
            end
            if last_cast > 0
              cast['since_last'] = cast['timestamp'] - last_cast
            end
            last_cast = cast['timestamp']
            @casts.each{|prev| prev['class'] = "indent-#{cast['class']}" if prev['class'] == 'unknown'}
          elsif cast['type'] == 'cast'
            if !begin_cast 
              if off_cd == 0 || cast['timestamp'] - (off_cd || @fp.started_at) <= @cds[@ability][:max_delay] * 1000
                cast['class'] = 'green'
              elsif cast['timestamp'] - (off_cd || @fp.started_at) <= @cds[@ability][:cd] * 1000
                cast['class'] = 'yellow'
              else
                cast['class'] = 'red'
              end
              if last_cast > 0
                cast['since_last'] = cast['timestamp'] - last_cast
              end
              last_cast = cast['timestamp']
              @casts.each{|prev| prev['class'] = "indent-#{cast['class']}" if prev['class'] == 'unknown'}
            end
            off_cd = 0
          end
        elsif cast['type'] == 'death'
          cast['class'] = 'red'
          cast['spacer'] = true
          @casts.each{|prev| prev['class'] = "indent-red" if prev['class'] == 'unknown'}
        else
          if @fp.track_casts.has_key?(@ability) && @fp.track_casts[@ability].has_key?(:buff) && @fp.track_casts[@ability][:buff] == cast['ability']
            if cast['type'] == 'buff_on'
              buff = true
            elsif cast['type'] == 'buff_off'
              buff = false
              cast['spacer'] = true
              if off_cd.to_i > 0
                cast['class'] = 'red'
                @casts.each{|prev| prev['class'] = "indent-red" if prev['class'] == 'unknown'}
              end
            end
          elsif !buff
            next
          elsif off_cd.to_i == 0
            @casts.last['spacer'] = true if @casts.count > 0
            next
          else
            cast['indent'] ||= true
            cast['class'] ||= "unknown"
          end
        end
        @casts << cast
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def status
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    player_id = params[:player_id]
    @fpr = FightParseRecord.find_by(report_id: report_id, fight_id: fight_id, player_id: player_id)
    @progress = Progress.find_by(model_type: 'FightParse', model_id: @fpr.id)

    respond_to do |format|
      format.js
    end
  end

  private
  def find_fight_parse_record
    @fpr = FightParseRecord.find_by(report_id: params[:report_id], fight_id: params[:fight_id], player_id: params[:player_id])
    if @fpr.nil?
      redirect_to report_path(params[:report_id])
      return 
    end
  end

  def validate_fp
    report_id = params[:report_id]
    fight_id = params[:fight_id]
    player_id = params[:player_id]
    @fight = Fight.find_by(report_id: report_id, fight_id: fight_id)
    @report = Report.find_by(report_id: report_id)
    if @fight.nil? || @report.nil?
      flash[:danger] = "Fight not found"
      redirect_to :root
      return 
    end
    @fp = @fpr.find_fp
    
    if @fp.nil? || ['unprocessed', 'queued', 'processing'].include?(@fpr.status)
      @progress = Progress.find_by(model_type: 'FightParse', model_id: @fpr.id)
      @changelogs = Changelog.where(fp_type: ['FightParse', "#{@fpr.spec} #{@fpr.class_type}"]).order(created_at: :desc)
      @hide_report = true
      render template: 'fight_parses/waiting'
      return
    end
    if ['failed', 'empty'].include? @fpr.status
      render template: 'fight_parses/failed'
      return
    end
    
    if @fp.version < @fp.class.latest_version || @fp.hotfix < @fp.class.latest_hotfix
      @not_latest = true
    end
  end

end
