class HomeController < ApplicationController
  def index
    if params.has_key?(:report_id)
      if (/\// =~ params[:report_id]).nil?
        report_id = params[:report_id].strip
        if report_id == ''
          flash[:danger] = "Please enter a report ID"
          redirect_to root_path and return 
        end
      else
        match = /\/reports\/(\w+)/.match(params[:report_id])
        if match.nil?
          flash[:danger] = "Invalid report ID"
          redirect_to root_path
          return
        else
          report_id = match[1]
        end
      end
      redirect_to report_path(report_id)
    else
      @changelogs = Changelog.order(id: :desc).limit(10).to_a
    end
  end

  def about
    
  end

  def changelog
    @spec = params[:spec]
    @changelogs = Changelog.where(fp_type: @spec).order(id: :desc).to_a
  end

  def logout
    redirect_to root_path
  end

  def error_404
    render file: "#{Rails.root}/public/404.html", status: 404
  end
end
