require "rails_helper"

RSpec.describe WorkflowEventAndActionValidator do
  let!(:user) { create(:confirmed_user, :with_home, login: 'Iggy') }
  let(:token) { create(:workflow_token, user: user) }
  let(:scm_extractor_payload) do
    {
      scm_extractor_payload: {
        scm: scm,
        event: event,
        action: action
      }
    }
  end
  let(:workflow) { create(:workflow, token: token, scm_extractor_payload: scm_extractor_payload) }


  subject do
    described_class.new.validate(workflow)
  end

  describe '#validate' do
    context 'when scm is GitHub' do
      contecxt 'Wnen the PR is new'
    end
  end

  describe '#validate' do
    let(:step_instructions) { {} }

    context 'when we feed a valid extractor payload from GitHub' do
      context 'for a new PR event' do
        let(:action) { 'opened' }

        it { expect(subject).to be_allowed_event_and_action }
      end

      context 'for an updated PR event' do
        let(:action) { 'synchronize' }

        it { expect(subject).to be_allowed_event_and_action }
      end
    end

    context 'when we feed a valid extractor payload from GitLab' do
      let(:scm_extractor_payload) do
        {
          scm: 'gitlab',
          event: 'Merge Request Hook',
          action: action
        }
      end

      context 'for a new MR event' do
        let(:action) { 'open' }

        it { expect(subject).to be_allowed_event_and_action }
      end

      context 'for a updated MR event' do
        let(:action) { 'update' }

        it { expect(subject).to be_allowed_event_and_action }
      end
    end
  end

end
