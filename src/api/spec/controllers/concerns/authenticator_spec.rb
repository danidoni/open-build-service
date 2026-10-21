RSpec.describe ApplicationController do # rubocop:disable RSpec/SpecFilePathFormat
  controller do
    include Authenticator

    def index; end
  end

  subject { get :index, params: {}, format: :xml }

  context 'proxy auth' do
    before do
      allow(Configuration).to receive(:proxy_auth_mode_enabled?).and_return(true)
      User.find_nobody! # avoid user nobody creation during examples
      request.headers['HTTP_X_USERNAME'] = 'hans'
      request.headers['HTTP_X_FIRSTNAME'] = 'Hans'
      request.headers['HTTP_X_LASTNAME'] = 'Sarpei'
      request.headers['HTTP_X_EMAIL'] = 'hans@sarpei.de'
    end

    describe '#extract_user sign up' do
      it { expect { subject }.to change(User, :count).by(1) }
      it { expect { subject }.to change(User, :session) }

      describe 'sign up disabled' do
        before do
          allow(Configuration).to receive(:registration).and_return('deny')
        end

        it { expect(subject.headers['X-Opensuse-Errorcode']).to eql('registration_disabled') }
        it { expect { subject }.not_to change(User, :session) }
      end
    end

    describe '#extract_user sign in' do
      let!(:user) { create(:confirmed_user, login: 'hans', email: 'hans@gmail.com') }

      it { expect { subject }.not_to change(User, :count) }
      it { expect { subject }.to change(User, :session) }
    end
  end

  context 'legacy session auth' do
    let!(:user) { create(:confirmed_user) }

    before do
      login(user)
    end

    describe '#extract_user' do
      it { expect { subject }.to change(User, :session) }
    end
  end

  context 'devise session auth' do
    include Devise::Test::ControllerHelpers

    let!(:user) { create(:confirmed_user, login: 'hans') }

    before do
      sign_in user
    end

    describe '#extract_user' do
      it { expect { subject }.to change(User, :session) }

      it 'sets the Warden user as the session user' do
        subject
        expect(User.session).to eq(user)
      end
    end
  end

  context 'basic auth' do
    let!(:user) { create(:confirmed_user, login: 'hans') }

    before do
      request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('hans:buildservice')}"
    end

    describe '#extract_user' do
      it { expect { subject }.to change(User, :session) }

      context 'with a wrong password' do
        before do
          request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('hans:wrong')}"
        end

        it { expect { subject }.not_to change(User, :session) }
      end

      context 'when anonymous access is off and the credentials are wrong' do
        before do
          allow(Configuration).to receive(:anonymous).and_return(false)
          request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('hans:wrong')}"
        end

        it { expect(subject.status).to eq(401) }
        it { expect(subject.headers['WWW-Authenticate']).to eq('basic realm="API login"') }
        it { expect(subject.headers['X-Opensuse-Errorcode']).to eql('authentication_required') }
      end

      context 'with a legacy password hash' do
        let!(:user) { create(:user_deprecated_password, login: 'hans') }

        it 'migrates the password to bcrypt on a successful Basic login' do
          subject
          expect(BCrypt::Password.new(user.reload.password_digest)).to be_is_password('buildservice')
          expect(user.deprecated_password).to be_nil
        end
      end

      describe 'wrong auth' do
        before do
          request.headers['HTTP_AUTHORIZATION'] = 'Digest blah=blubb'
        end

        it { expect { subject }.not_to change(User, :session) }
      end
    end
  end

  describe '#check_user_state' do
    let!(:user) { create(:user) }

    before do
      login(user)
    end

    it { expect { subject }.not_to change(User, :session) }
    it { expect(subject.headers['X-Opensuse-Errorcode']).to eql('unconfirmed_user') }
  end

  describe '#check_anonymous_access' do
    before do
      allow(Configuration).to receive(:anonymous).and_return(false)
    end

    it { expect(subject.headers['X-Opensuse-Errorcode']).to eql('authentication_required') }
  end

  describe '#track_user_login' do
    let!(:user) { create(:confirmed_user, login: 'hans') }

    before do
      user.update_columns(last_logged_in_at: 1.week.ago) # rubocop:disable Rails/SkipsModelValidations
      login(user)
    end

    it { expect { subject }.to(change { user.reload.last_logged_in_at }) }
  end
end
