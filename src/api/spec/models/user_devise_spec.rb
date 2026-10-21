RSpec.describe User do
  describe '#valid_password?' do
    let(:user) { create(:confirmed_user, login: 'hans') }

    it { expect(user.valid_password?('buildservice')).to be true }
    it { expect(user.valid_password?('wrong')).to be false }

    context 'without any password hash' do
      before { user.update_columns(password_digest: nil) } # rubocop:disable Rails/SkipsModelValidations

      it { expect(user.valid_password?('buildservice')).to be false }
    end

    context 'with a legacy password hash' do
      let(:user) { create(:user_deprecated_password) }

      it { expect(user.valid_password?('buildservice')).to be true }

      it 'migrates the password to bcrypt on the first successful check' do
        user.valid_password?('buildservice')
        expect(BCrypt::Password.new(user.password_digest)).to be_is_password('buildservice')
      end

      it { expect(user.valid_password?('wrong')).to be false }
    end
  end

  describe 'encrypted_password alias (Devise reads the password_digest column)' do
    let(:user) { create(:confirmed_user, login: 'hans') }

    it { expect(user.encrypted_password).to eq(user.password_digest) }
    it { expect(user.password_digest).to be_present }
  end
end
