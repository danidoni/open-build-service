# Devise DatabaseAuthenticatable Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the custom `has_secure_password` + `Webui::SessionController` login system with Devise's `DatabaseAuthenticatable` for the `development` and `test` environments, leaving proxy auth (production) and API Basic Auth untouched.

**Architecture:** Devise is added as a permanent gem dependency but only activated as the auth backend in `development` and `test`. The `Authenticator` concern's `session[:login]` branch is replaced with Devise's `current_user` (Warden-backed). The proxy auth branch and the API Basic Auth branch are left completely unchanged. Custom session path URLs are preserved via Devise route configuration so proxy-mode conditionals in views/helpers require no changes.

**Tech Stack:** Rails 7, Devise gem, Warden (Devise's rack middleware), bcrypt, RSpec + Devise test helpers.

---

## Open Decision

> **`mark_login!` timing:** Currently `track_user_login` in `Authenticator` calls `User.session.mark_login!` on every request. With Devise owning the session, this could instead move to Devise's `after_database_authentication` hook (fires once per login). This plan keeps `mark_login!` on every request for now (preserving existing behaviour) — revisit in a follow-up.

---

## Background: What Exists Today

- **`app/models/user.rb:17`** — `has_secure_password validations: false`
- **`app/models/user.rb:266-281`** — `authenticate` override: handles deprecated MD5/crypt passwords, migrates them to bcrypt on success
- **`app/models/user.rb:841-843`** — `password_validation`: requires either `password_digest` or `deprecated_password`
- **`app/controllers/concerns/authenticator.rb:16-30`** — `extract_user`: branches on proxy auth → `session[:login]` → Basic Auth
- **`app/controllers/webui/session_controller.rb`** — custom login/logout controller (25 lines)
- **`config/routes/webui.rb:437-443`** — session routes wrapped in `RoutesHelper::SessionAuthMatcher` (only active when proxy auth is off)
- **`app/helpers/authentication_protocol_helper.rb`** — `log_in_params`, `log_out_url`, `return_to_location` all branch on `proxy_auth_mode_enabled?`; the non-proxy branches use `session_path`, `reset_session_path`, `new_session_path`
- **`spec/support/features/features_authentication.rb:3`** — `page.set_rack_session(login: user.login)`
- **`spec/support/controllers/controllers_authentication.rb:3`** — `request.session[:login] = user.login`
- **`app/views/webui/session/_form.html.haml`** — posts `username` + `password` flat params

---

## Task 1: Add Devise to the Gemfile

**Files:**
- Modify: `src/api/Gemfile`

**Step 1: Add the gem**

In `src/api/Gemfile`, add after the `bcrypt` line (line 47):

```ruby
gem 'devise'
```

**Step 2: Install**

```bash
bundle install
```

Expected: Devise and its dependencies (warden, orm_adapter, responders) installed.

**Step 3: Commit**

```bash
git add src/api/Gemfile src/api/Gemfile.lock
git commit -m "Add devise gem"
```

---

## Task 2: Generate Devise Initializer and Configure It

**Files:**
- Create: `src/api/config/initializers/devise.rb` (generated)

**Step 1: Run the installer**

```bash
cd src/api && rails generate devise:install
```

This creates `config/initializers/devise.rb` and prints instructions — ignore the instructions about adding routes and flash messages (we handle those manually).

**Step 2: Configure authentication key**

In `config/initializers/devise.rb`, find and set:

```ruby
config.authentication_keys = [:login]
```

This tells Devise to look up users by `login` instead of `email`.

**Step 3: Set the mailer sender (required)**

```ruby
config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
```

(Leave as-is for now — mailer modules are not being activated.)

**Step 4: Commit**

```bash
git add config/initializers/devise.rb
git commit -m "Add Devise initializer, configure authentication_keys to :login"
```

---

## Task 3: Update the User Model

**Files:**
- Modify: `src/api/app/models/user.rb`

### What changes and why

| Current | After | Reason |
|---|---|---|
| `has_secure_password validations: false` | `devise :database_authenticatable, validations: false` | Devise's module wraps the same bcrypt logic but integrates with Warden |
| `def authenticate(unencrypted_password)` | `def valid_password?(password)` | Devise calls `valid_password?` instead of `authenticate` |
| `password_validation` private method | keep as-is | Still needed — Devise with `validations: false` disables its own presence check, just like `has_secure_password validations: false` did |

> **Note:** `devise :database_authenticatable` should only be included in `development` and `test`. Use an environment guard:
>
> ```ruby
> devise :database_authenticatable if Rails.env.local?
> ```
>
> `Rails.env.local?` is true for both `development` and `test` (Rails 7.1+).

**Step 1: Replace `has_secure_password`**

Remove:
```ruby
has_secure_password validations: false
```

Add (near the top of the model, after the enum declarations):
```ruby
devise :database_authenticatable if Rails.env.local?
```

**Step 2: Rename `authenticate` to `valid_password?`**

Replace (`app/models/user.rb:266-281`):
```ruby
def authenticate(unencrypted_password)
  if deprecated_password
    if deprecated_password_equals?(unencrypted_password)
      update(password: unencrypted_password, deprecated_password: nil, deprecated_password_salt: nil, deprecated_password_hash_type: nil)
      return self
    end

    return false
  end

  super
end
```

With:
```ruby
def valid_password?(password)
  if deprecated_password
    return false unless deprecated_password_equals?(password)

    update(password: password, deprecated_password: nil, deprecated_password_salt: nil, deprecated_password_hash_type: nil)
    return true
  end

  super
end
```

> **Why `true`/`false` instead of `self`/`false`:** Devise's `valid_password?` must return a boolean. The old `authenticate` returned `self` to satisfy `has_secure_password`'s convention — that's no longer needed.

**Step 3: Add `find_for_database_authentication`**

Add as a class method (near `find_with_credentials`):

```ruby
def self.find_for_database_authentication(warden_conditions)
  find_by(login: warden_conditions[:login])
end
```

This tells Devise to look up by `login` column when authenticating.

**Step 4: Run existing model specs to verify nothing is broken**

```bash
cd src/api && bundle exec rspec spec/models/user_spec.rb
```

Expected: all pass (the deprecated password migration logic is preserved in `valid_password?`).

**Step 5: Commit**

```bash
git add app/models/user.rb
git commit -m "Replace has_secure_password with devise :database_authenticatable, preserve deprecated password migration in valid_password?"
```

---

## Task 4: Update Routes

**Files:**
- Modify: `src/api/config/routes/webui.rb`

**Step 1: Replace the session resource block**

Find (`config/routes/webui.rb:437-443`):
```ruby
constraints(RoutesHelper::SessionAuthMatcher) do
  resource :session, only: %i[new create], controller: 'webui/session' do
    collection do
      get :reset
    end
  end
end
```

Replace with:
```ruby
constraints(RoutesHelper::SessionAuthMatcher) do
  devise_for :users,
             controllers: { sessions: 'devise/sessions' },
             path: 'session',
             path_names: { sign_in: 'new', sign_out: 'reset', sign_up: '' }
end
```

> **Why these path_names:**
> - `sign_in: 'new'` → `GET /session/new` (login page — same as before)
> - `sign_out: 'reset'` → `DELETE /session/reset` (logout — same path, method changes from GET to DELETE)
> - `path: 'session'` → keeps the `/session` prefix
>
> **Note on logout method change:** The current `GET /session/reset` becomes `DELETE /session/reset` (Devise default). The logout link in the layout must use `method: :delete`. Check `app/views/layouts/webui/webui.html.haml` for the logout link and update it.

**Step 2: Verify routes**

```bash
cd src/api && bundle exec rails routes | grep session
```

Expected output should include:
```
new_user_session     GET    /session/new     devise/sessions#new
user_session         POST   /session         devise/sessions#create
destroy_user_session DELETE /session/reset   devise/sessions#destroy
```

**Step 3: Commit**

```bash
git add config/routes/webui.rb
git commit -m "Replace custom session routes with devise_for, preserve existing URL paths"
```

---

## Task 5: Delete the Custom Session Controller and View

**Files:**
- Delete: `src/api/app/controllers/webui/session_controller.rb`
- Delete: `src/api/app/views/webui/session/new.html.haml`
- Keep: `src/api/app/views/webui/session/_form.html.haml` (reused in Task 6)

**Step 1: Delete the controller**

```bash
rm src/api/app/controllers/webui/session_controller.rb
```

**Step 2: Delete the old login page view**

```bash
rm src/api/app/views/webui/session/new.html.haml
```

**Step 3: Generate Devise views (sessions only)**

```bash
cd src/api && rails generate devise:views -v sessions
```

This creates `app/views/devise/sessions/new.html.erb`. We will replace its content in Task 6.

**Step 4: Commit**

```bash
git add -A
git commit -m "Delete custom SessionController and login view, generate Devise session views"
```

---

## Task 6: Update Login Form for Devise Params

**Files:**
- Modify: `src/api/app/views/devise/sessions/new.html.erb` (rename to `.haml` if preferred)
- Modify: `src/api/app/views/webui/session/_form.html.haml`

Devise expects params namespaced as `user[login]` and `user[password]`. The current form uses flat `username` and `password` params.

**Step 1: Update the form partial**

Replace `app/views/webui/session/_form.html.haml` with:

```haml
- label_css ||= ''
- button_css ||= ''

- if ::Configuration.proxy_auth_mode_enabled?
  = form_tag(log_in_params[:url], log_in_params[:options]) do
    = hidden_field_tag(:context, 'default')
    = hidden_field_tag(:proxypath, 'reserve')
    = hidden_field_tag(:message, 'Please log in')
    - if with_redirect
      = hidden_field_tag(:url, return_to_location)
    .mb-3
      = label_tag(:username, 'Username', class: label_css)
      = text_field_tag(:username, nil, placeholder: 'User Name', required: true, id: 'user-login', class: 'form-control')
    .mb-3
      = label_tag(:password, 'Password', class: label_css)
      = password_field_tag(:password, nil, placeholder: 'Password', required: true, id: 'user-password', class: 'form-control')
    .clearfix
      = submit_tag('Log In', name: 'login', class: "btn btn-primary #{button_css}")
      - if with_sign_up && can_sign_up?
        %span or
        %span= sign_up_link
- else
  = form_for(resource, as: resource_name, url: session_path(resource_name)) do |f|
    .mb-3
      = f.label :login, 'Username', class: label_css
      = f.text_field :login, placeholder: 'User Name', required: true, autofocus: true, id: 'user-login', class: 'form-control'
    .mb-3
      = f.label :password, 'Password', class: label_css
      = f.password_field :password, placeholder: 'Password', required: true, id: 'user-password', class: 'form-control'
    .clearfix
      = f.submit 'Log In', name: 'login', class: "btn btn-primary #{button_css}"
      - if with_sign_up && can_sign_up?
        %span or
        %span= sign_up_link
```

> **Why split on `proxy_auth_mode_enabled?`:** The proxy form uses `form_tag` with an external URL and specific hidden fields. The Devise form must use `form_for(resource, ...)` so Devise provides the resource object and helpers. The `resource` and `resource_name` locals come from Devise's `SessionsController`.

**Step 2: Update Devise's generated view to render the partial**

Replace `app/views/devise/sessions/new.html.erb` content with (rename to `.haml`):

```haml
- @pagetitle = 'Please Log In'

.card
  .card-body#loginform
    .col-lg-6.ps-0
      %h3= @pagetitle
      = render partial: 'webui/session/form', locals: { with_sign_up: true, with_redirect: true }
```

**Step 3: Update `login_spec.rb` field names**

In `spec/features/webui/login_spec.rb`, update `fill_in` calls from `'username'` to match the new field ids Devise generates from `f.text_field :login` (id becomes `user_login`) and `f.password_field :password` (id becomes `user_password`):

```ruby
fill_in 'user_login', with: user.login
fill_in 'user_password', with: 'buildservice'
```

**Step 4: Run the login feature spec**

```bash
cd src/api && bundle exec rspec spec/features/webui/login_spec.rb
```

Expected: all pass.

**Step 5: Commit**

```bash
git add app/views/webui/session/_form.html.haml app/views/devise/ spec/features/webui/login_spec.rb
git commit -m "Update login form to use Devise resource params (user[login], user[password])"
```

---

## Task 7: Update the Authenticator Concern

**Files:**
- Modify: `src/api/app/controllers/concerns/authenticator.rb`

**Step 1: Replace the `session[:login]` branch with `current_user`**

Find (`authenticator.rb:16-30`):
```ruby
def extract_user
  user = if ::Configuration.proxy_auth_mode_enabled?
           find_or_create_proxy_user
         elsif request.session[:login] # Webui Session Auth
           User.find_by!(login: request.session[:login])
         elsif authorization_headers.present? # API Basic Auth
           basic_auth_info = basic_auth
           User.find_with_credentials(basic_auth_info[:login], basic_auth_info[:password])
         end

  return unless user

  User.session = user
  Rails.logger.debug { "User.session set to #{User.possibly_nobody.login}" }
end
```

Replace with:
```ruby
def extract_user
  user = if ::Configuration.proxy_auth_mode_enabled?
           find_or_create_proxy_user
         elsif authorization_headers.present? # API Basic Auth
           basic_auth_info = basic_auth
           User.find_with_credentials(basic_auth_info[:login], basic_auth_info[:password])
         else
           current_user # Devise/Warden — returns nil if not signed in
         end

  return unless user

  User.session = user
  Rails.logger.debug { "User.session set to #{User.possibly_nobody.login}" }
end
```

> **Why Basic Auth before `current_user`:** API clients send `Authorization` headers but no Warden session. Checking `authorization_headers.present?` first ensures those requests still hit the custom Basic Auth path. WebUI requests from signed-in users won't have an `Authorization` header, so they fall through to `current_user`.

> **Why `current_user` works here:** Devise mounts Warden as Rack middleware. By the time any controller action runs, Warden has already populated `env['warden']`. `current_user` calls `warden.authenticate(scope: :user)` which reads the Warden session. This works in development and test (where Devise routes are mounted), and returns nil in proxy mode (where they aren't — and the proxy branch runs first anyway).

**Step 2: Run the full controller spec suite**

```bash
cd src/api && bundle exec rspec spec/controllers/
```

Expected: all pass.

**Step 3: Commit**

```bash
git add app/controllers/concerns/authenticator.rb
git commit -m "Replace session[:login] lookup with Devise current_user in Authenticator"
```

---

## Task 8: Update Test Auth Helpers

**Files:**
- Modify: `src/api/spec/support/features/features_authentication.rb`
- Modify: `src/api/spec/support/controllers/controllers_authentication.rb`

### Feature specs (`type: :feature`)

`page.set_rack_session(login: user.login)` writes directly to the Rack session using the old `login:` key. With Warden, the session key is different. Use Devise's built-in test helper `sign_in` instead:

Replace `spec/support/features/features_authentication.rb`:
```ruby
module FeaturesAuthentication
  def login(user)
    sign_in(user)
  end

  def logout
    sign_out(:user)
  end
end

RSpec.configure do |c|
  c.include Devise::Test::IntegrationHelpers, type: :feature
  c.include FeaturesAuthentication, type: :feature
end
```

> `Devise::Test::IntegrationHelpers` provides `sign_in`/`sign_out` for Capybara/integration specs. It writes the Warden session correctly without a browser round-trip.

### Controller specs (`type: :controller`)

Replace `spec/support/controllers/controllers_authentication.rb`:
```ruby
module ControllersAuthentication
  def login(user)
    sign_in(user)
  end

  def logout
    sign_out(:user)
  end
end

RSpec.configure do |c|
  c.include Devise::Test::ControllerHelpers, type: :controller
  c.include ControllersAuthentication, type: :controller
end
```

> `Devise::Test::ControllerHelpers` provides `sign_in`/`sign_out` for controller specs by directly setting the Warden env.

### Model and component specs — no changes needed

`spec/support/models/models_authentication.rb` and `spec/support/view_component.rb` set `User.session` directly — they bypass the session/Warden entirely and remain valid.

**Step 1: Update both files as above**

**Step 2: Run the full spec suite**

```bash
cd src/api && bundle exec rspec spec/
```

Expected: all pass.

**Step 3: Commit**

```bash
git add spec/support/features/features_authentication.rb spec/support/controllers/controllers_authentication.rb
git commit -m "Update test auth helpers to use Devise sign_in/sign_out helpers"
```

---

## Task 9: Update Logout Link to Use DELETE Method

**Files:**
- Modify: `src/api/app/views/layouts/webui/webui.html.haml`

Devise's `destroy` action (logout) requires `DELETE`, not `GET`. The current `GET /session/reset` becomes `DELETE /session/reset`.

**Step 1: Find the logout link**

```bash
grep -n "Logout\|log_out_url\|reset_session" src/api/app/views/layouts/webui/webui.html.haml
```

**Step 2: Ensure `method: :delete` is present**

The logout link goes through `log_out_url` from `AuthenticationProtocolHelper`. In the non-proxy branch (`authentication_protocol_helper.rb:31`), `log_out_url` returns `reset_session_path` — which now maps to `destroy_user_session_path`. The HTTP method must be `:delete`.

Find the logout link in the layout and ensure it uses:
```haml
= link_to 'Logout', log_out_url, data: { turbo_method: :delete }
```

Or if the app uses `button_to`:
```haml
= button_to 'Logout', log_out_url, method: :delete
```

**Step 3: Run logout feature spec**

```bash
cd src/api && bundle exec rspec spec/features/webui/login_spec.rb -e "logout"
```

Expected: passes.

**Step 4: Commit**

```bash
git add app/views/layouts/webui/webui.html.haml
git commit -m "Update logout link to use DELETE method for Devise sessions#destroy"
```

---

## Task 10: Final Verification

**Step 1: Run linter**

```bash
cd src/api && bundle exec rubocop
```

Fix any offences introduced.

**Step 2: Run full spec suite**

```bash
cd src/api && bundle exec rspec spec/
```

Expected: all pass.

**Step 3: Smoke test manually in development**

```bash
cd src/api && bundle exec rails server
```

- Visit `http://localhost:3000/session/new` — login page renders
- Login with a valid user — redirects to user profile
- Logout — session cleared, redirected to root
- Login with wrong password — "Authentication Failed" flash

**Step 4: Final commit (if any fixes were needed)**

```bash
git add -A
git commit -m "Fix any linter and test issues from Devise migration"
```

---

## Files Changed Summary

| File | Action |
|---|---|
| `src/api/Gemfile` | Add `devise` gem |
| `src/api/config/initializers/devise.rb` | Generated + configure `authentication_keys: [:login]` |
| `src/api/app/models/user.rb` | `has_secure_password` → `devise :database_authenticatable if Rails.env.local?`; `authenticate` → `valid_password?`; add `find_for_database_authentication` |
| `src/api/config/routes/webui.rb` | `resource :session` → `devise_for :users` with path config |
| `src/api/app/controllers/webui/session_controller.rb` | **Deleted** |
| `src/api/app/views/webui/session/new.html.haml` | **Deleted** |
| `src/api/app/views/devise/sessions/new.html.haml` | Generated + updated to render existing form partial |
| `src/api/app/views/webui/session/_form.html.haml` | Split on `proxy_auth_mode_enabled?`; Devise `form_for` for dev/test |
| `src/api/app/controllers/concerns/authenticator.rb` | `session[:login]` branch → `current_user` |
| `src/api/app/views/layouts/webui/webui.html.haml` | Logout link → `method: :delete` (Turbo-aware) |
| `src/api/spec/support/features/features_authentication.rb` | `set_rack_session` → `Devise::Test::IntegrationHelpers` |
| `src/api/spec/support/controllers/controllers_authentication.rb` | `request.session[:login]` → `Devise::Test::ControllerHelpers` |
| `src/api/spec/features/webui/login_spec.rb` | Update `fill_in` field names to Devise's generated ids |
