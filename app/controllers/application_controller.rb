class ApplicationController < ActionController::Base
  helper_method :show_left_menu?

  layout :layout_by_resource
  
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_current_attributes
  #before_action :store_current_user
  before_action :set_locale

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

  def flash_message(model, action)
    I18n.t("notices.#{action}.success", model: model.model_name.human)
  end

  protected

  def set_locale
    if params[:locale]
      cookies[:locale] = params[:locale]
      I18n.locale = params[:locale]
    elsif cookies[:locale]
      I18n.locale = cookies[:locale]
    else
      I18n.locale = I18n.default_locale
    end
  end

  private

  def set_tenant
    if current_user
      set_current_tenant(current_user.organization)
    end
  end

  def set_current_attributes
    Current.user = current_user
    Current.organization = current_user&.organization
  end

  def store_current_user
    RequestStore.store[:current_user] = current_user
  end

  def layout_by_resource
    if turbo_frame_request?
      false
    elsif user_signed_in?
      'application'
    else
      'sessions'
    end
  end

end
