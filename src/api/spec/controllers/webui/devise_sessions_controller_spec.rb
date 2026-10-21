RSpec.describe Webui::DeviseSessionsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:confirmed_user, login: 'tom') }

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST #create' do
    subject { post :create, params: { username: user.login, password: 'buildservice' } }

    before do
      subject
    end

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

  describe 'GET #destroy' do
    before do
      sign_in user
      session[:login] = user.login
      get :destroy
    end

    it { expect(session[:login]).to be_nil }
    it { expect(controller.send(:warden).user(:user)).to be_nil }
    it { expect(response).to redirect_to root_path }
  end
end
