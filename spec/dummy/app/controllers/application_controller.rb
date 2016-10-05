class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_locale

  def setting
    session[:model] = params[:orm]
    session[:locale] = I18n.locale_available?(params[:lang]) ? params[:lang] : :en
    session[:user_id] = params[:login_user]
    head :ok
  end

  def current_user
    if session[:model] == "Mongoid"
      Mongo::User.where(id: session[:user_id]).first
    else
      Ar::User.where(id: session[:user_id]).first
    end
  end

  protected
  def set_locale
    I18n.locale = session[:locale]
  end
end
