RSpec.describe Webui::SessionController do
  # In development and test, /session is served by Webui::DeviseSessionsController.
  # Production still uses this controller, so this spec draws its own route set.
  # The shared application routes are not changed.
  let(:user) { create(:confirmed_user, login: 'tom') }

  before do
    route_set = ActionDispatch::Routing::RouteSet.new
    route_set.draw do
      root to: 'webui/main#index'
      get 'users/:login' => 'webui/users#show', as: :user
      post 'session' => 'webui/session#create'
      get 'session/new' => 'webui/session#new', as: :new_session
      get 'session/reset' => 'webui/session#reset', as: :reset_session
    end
    # Rails reads the @routes instance variable to use a custom route set.
    @routes = route_set
    subject
  end

  describe 'POST #create' do
    subject { post :create, params: { username: user.login, password: 'buildservice' } }

    it { expect(session[:login]).to eq(user.login) }
    it { expect(response).to redirect_to user_url(user) }

    context 'wrong password' do
      subject { post :create, params: { username: user.login, password: 'password123' } }

      it { expect(session[:login]).to be_nil }
      it { expect(flash[:error]).to eq('Authentication Failed') }
    end

    context 'wrong user' do
      subject { post :create, params: { username: 'hans', password: 'buildservice' } }

      it { expect(session[:login]).to be_nil }
      it { expect(flash[:error]).to eq('Authentication Failed') }
    end
  end
end
