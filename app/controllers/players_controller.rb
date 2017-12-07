class PlayersController < ApplicationController
  before_action :find_player, only: :show

  def show
    if @player.nil?
      flash[:danger] = "Player not found"
      redirect_to :root
      return 
    end
    @recent_views.unshift ({'type'=> 'player', 'id'=> @player_id, 'name'=> @player.player_name, 'class'=> @player.class_type})
    @recent_views = @recent_views.uniq[0..4]
    cookies.permanent[:recent_views] = JSON.generate(@recent_views)

    @zones = Zone.where(enabled: true).order(:order_id).includes(:bosses)
    @player_bosses = {}
    FightParseRecord.where(report_id: @report_ids, player_id: @player_id).where("spec is not null and spec != ''").each do |fp|
      @player_bosses[fp.boss_id] ||= {}
      @player_bosses[fp.boss_id][fp.difficulty] ||= 0
      @player_bosses[fp.boss_id][fp.difficulty] += 1
    end
    @processing = FightParseRecord.where(report_id: @report_ids, player_id: @player_id, status: [FightParseRecord.statuses[:queued], FightParseRecord.statuses[:processing]]).count
  end

  def search
    @char_name = params[:char_name]
    @chars = Player.where("player_name ILIKE (?)", "%#{@char_name}%").limit(20).pluck(:player_id, :player_name, :class_type)
    player_ids = @chars.map{|c| c[0]}
    @report_counts = ReportPlayer.where(player_id: player_ids).group(:player_id).count
  end

  private
  def find_player
    @player_id = params[:id] || params[:player_id]
    @player = Player.find_by(player_id: @player_id)
    @report_ids = ReportPlayer.where(player_id: @player_id).pluck(:report_id)
  end
end
