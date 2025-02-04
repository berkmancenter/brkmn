class UsersController < ApplicationController
  # GET /cas_logout
  # Logs out the current user and redirects to the CAS server logout page
  def cas_logout
    sign_out(current_user)
    session.destroy
    redirect_to "#{Brkmn::Application.config.rack_cas.server_url}/logout"
  end
end
