# Login form and session for development and test (Devise DatabaseAuthenticatable).
# Production does not use this controller: proxy mode removes the session routes.
class Webui::DeviseSessionsController < Devise::SessionsController
  # Views and partials of the login form (new.html.haml, _form, _breadcrumb_items) live in webui/session.
  def _prefixes
    super + ['webui/session']
  end

  # Same as the legacy session controller: the login form must work without a user.
  skip_before_action :extract_user, :check_anonymous_access

  # The require_no_authentication callback sends a signed-in user to another page.
  # This controller skips it. A signed-in user can log in again.
  # The verify_signed_out_user callback returns an error when no Devise session exists.
  # This controller skips it for destroy. Logout always clears the session.
  skip_before_action :require_no_authentication, raise: false
  skip_before_action :verify_signed_out_user, only: :destroy, raise: false

  def new
    self.resource = User.new
    render 'webui/session/new'
  end

  def create
    # find_with_credentials keeps the login counters (mark_login!, count_login_failure) and the
    # legacy hash to bcrypt migration.
    user = User.find_with_credentials(params.fetch(:username, ''), params.fetch(:password, ''))

    if user
      sign_in(resource_name, user)
      # Readers that still use session[:login] (RoleMatcher, sign-up) keep working.
      session[:login] = user.login
      # Redirect to user_path instead of back to new_session_path...
      request.env['HTTP_REFERER'] = nil if request.referer.to_s.end_with?(new_session_path)

      redirect_back_or_to(user_path(user), allow_other_host: false)
    else
      redirect_back_or_to(root_path, error: 'Authentication Failed', allow_other_host: false)
    end
  end

  # Clears the Warden session and the legacy session key, so both kinds of login end here.
  def destroy
    reset_session

    redirect_to root_path
  end
end
