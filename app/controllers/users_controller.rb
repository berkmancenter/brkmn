class UsersController < ApplicationController
  # GET /cas_logout
  # Logs out the current user and redirects to the CAS server logout page
  def cas_logout
    sign_out(current_user)
    session.destroy

    # Without CAS there is no CAS server (and no rack_cas config) to go to.
    return redirect_to after_sign_out_path_for(:user) unless Rails.application.config.devise_auth_type == "cas"

    redirect_to "#{Brkmn::Application.config.rack_cas.server_url}/logout", allow_other_host: true
  end
end
