class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_locale

  def setting
    session[:model] = params[:orm]
    session[:locale] = I18n.locale_available?(params[:lang]) ? params[:lang] : :en
    head :ok
  end

  protected
  def set_locale
    I18n.locale = session[:locale]
  end
end
