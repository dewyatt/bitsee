class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @secrets = Secret.paginate(page: params[:page], per_page: 20)
  end

end
