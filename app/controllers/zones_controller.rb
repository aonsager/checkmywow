class ZonesController < ApplicationController
  
  def refresh
    if Rails.env.development?
      response = HTTParty.get("https://www.warcraftlogs.com:443/v1/zones?api_key=#{ENV['WCL_API_KEY']}")
      zones = JSON.parse(response.body)
      zones.each do |zone|
        next if zone['id'] < 6
        if !Zone.exists?(:id => zone['id'])
          Zone.create(
            id: zone['id'],
            name: zone['name']
          )
        end
        zone['encounters'].each do |enc|
          if !Boss.exists?(:id => enc['id'])
            Boss.create(
              id: enc['id'],
              name: enc['name'],
              zone_id: zone['id']
            )
          end
        end
      end
    end
    redirect_to action: :index
  end

  def index
    @zones = Zone.all.order(:order_id)
  end

end
