class Zone < ActiveRecord::Base
  has_many :bosses, dependent: :destroy

  def self.enabled_zones
    return [6,7,8,10,11,12,13,15]
  end
end