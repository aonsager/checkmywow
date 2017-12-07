class Player < ActiveRecord::Base
  has_many :report_players
  has_many :reports, through: :report_players
  serialize :boss_counts, Hash

  def self.player_tag(player_name, class_type, spec_type='', css=true)
    if class_type.nil?
      return "<span>#{player_name}</span>".html_safe
    elsif css
      return "<span class='#{class_type} text'>".html_safe + ActionController::Base.helpers.image_tag("class/#{class_type.downcase}#{spec_type.blank? ? '' : '/'+spec_type.downcase}.jpg", size: '21x21', class: 'icon') + '&nbsp;&nbsp;'.html_safe + player_name + "</span>".html_safe
    else
      return "<span>".html_safe + ActionController::Base.helpers.image_tag("class/#{class_type.downcase}#{spec_type.blank? ? '' : '/'+spec_type.downcase}.jpg", size: '21x21', class: 'icon') + '&nbsp;&nbsp;'.html_safe + player_name + "</span>".html_safe
    end
  end

  def player_tag
    return "<span class='#{self.class_type} text'>".html_safe + ActionController::Base.helpers.image_tag("class/#{self.class_type}.jpg", size: '21x21', class: 'icon') + '&nbsp;&nbsp;'.html_safe + self.player_name
  end  
end