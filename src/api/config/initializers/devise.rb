# frozen_string_literal: true

# Devise DatabaseAuthenticatable is active in development and test only.
# Production uses proxy mode, see Configuration.proxy_auth_mode_enabled?.
Devise.setup do |config|
  require 'devise/orm/active_record'

  # Users log in with their OBS login, not an e-mail address.
  config.authentication_keys = [:login]

  # Log out with GET (existing logout links) or DELETE. This mimics existing OBS legacy authentication behavior.
  config.sign_out_via = %i[get delete]

  # Cost of newly created bcrypt hashes. Existing hashes keep their own cost. Tests use the minimum cost to stay fast.
  config.stretches = Rails.env.test? ? 1 : 12

  # Existing bcrypt hashes stay valid, so no pepper.
  # config.pepper is intentionally not set.

  config.navigational_formats = ['*/*', :html]

  # Devise controllers use the WebUI base, like the old session controller. Its layout, helpers
  # and view paths apply. ApplicationController would require login for every action.
  config.parent_controller = 'Webui::WebuiController'
end
