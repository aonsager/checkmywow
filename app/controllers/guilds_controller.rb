class GuildsController < ApplicationController
  def show
    @guild_id = params[:id].to_i
    @guild = Guild.find(@guild_id) rescue nil
    if @guild.nil?
      flash[:danger] = "Guild not found"
      redirect_to controller: 'players', action: 'search'
      return 
    end
    @recent_views.unshift ({'type'=> 'guild', 'id'=> @guild_id, 'name'=> @guild.name})
    @recent_views = @recent_views.uniq[0..4]
    cookies.permanent[:recent_views] = JSON.generate(@recent_views)
    @reports = @guild.reports.order(started_at: :desc).page params[:page]
  end

  def reload
    guild_id = params[:guild_id].to_i
    guild = Guild.find(guild_id) rescue nil
    if guild.nil?
      flash[:danger] = "Guild not found #{params}"
      redirect_to controller: 'players', action: 'search'
      return 
    end
    guild.queued!
    Resque.enqueue(GuildParser, guild.id)
    redirect_to action: 'show', id: guild.id
  end

  def search
    region = params[:region].to_s.upcase
    server = params[:server].to_s.capitalize
    server_slug = server.gsub(/ /, '-').gsub(/'/, '').downcase
    name = params[:name].to_s.titleize

    guild = Guild.find_by(region: region, server: server, name: name)
    if guild.nil?
      begin
        response = HTTParty.get("https://www.warcraftlogs.com:443/v1/reports/guild/#{URI.escape(name)}/#{URI.escape(server_slug)}/#{URI.escape(region)}?api_key=#{ENV['WCL_API_KEY']}", timeout: 10)
        report_obj = JSON.parse(response.body)
        if report_obj.is_a?(Hash) && report_obj.has_key?('error')
          flash[:danger] = report_obj['error']
          redirect_to controller: 'players', action: 'search' and return
        else
          guild = Guild.create(region: region, server: server, server_slug: server_slug, name: name, status: Guild.statuses[:queued])
          Resque.enqueue(GuildParser, guild.id)
        end
      rescue
        flash[:danger] = "There was an error performing the request. Please try again at a later time."
        redirect_to controller: 'players', action: 'search'
        return 
      end
    end
    redirect_to action: 'show', id: guild.id
  end
end
