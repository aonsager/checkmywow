class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :bar_width
  helper_method :success_label
  helper_method :spec_tag
  before_filter :set_cookies

  def set_cookies
    cookies.permanent[:recent_views] ||= []
    @recent_views = JSON.parse(cookies.permanent[:recent_views].to_s) rescue []
  end
  
  def bar_width(num, max)
    return 10 if num.nil? || num == 0
    return 100 if max.nil? || max == 0
    return [100,[100 * num / max, 10].max].min
  end

  def success_label(type)
    case type
    when 'good'
      return "<span class='small green'>Great</span>"
    when 'ok'
      return "<span class='small yellow'>Can be improved</span>"
    when 'bad'
      return "<span class='small red'>Needs improvement</span>"
    end
  end

  def spec_tag(class_type, spec_type)
    return "<span>".html_safe + ActionController::Base.helpers.image_tag("class/#{class_type.downcase}#{spec_type.nil? ? "" : "/#{spec_type.downcase}.jpg"}", size: '21x21', class: 'icon') + '&nbsp;&nbsp;'.html_safe + spec_type
  end

  rescue_from ActionView::MissingTemplate do |exception|
    if Rails.env.production?
      flash[:danger] = "Invalid URL"
      redirect_to :root
    else
      raise exception
    end
  end
end
