class ApplicationController < ActionController::Base
  helper_method :show_left_menu?

  layout :layout_by_resource

  if Rails.env.production?
    rescue_from ActionController::RoutingError, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound do |exception|
      render_error 404, exception
    end

    rescue_from Exception do |exception|
      ExceptionNotifier.notify_exception(exception,:env => request.env, :data => {:message => "Błąd nieprzechwycony"})
      render_error 500, exception
    end

    rescue_from CanCan::AccessDenied do |exception|  
      if current_user
        render_error 403, exception
      else
        redirect_to new_user_session_path
      end
    end
  end

  def show_left_menu?
    true
  end

  private

  def layout_by_resource
    if user_signed_in?
      'application'
    else
      'sessions'
    end
  end

end
