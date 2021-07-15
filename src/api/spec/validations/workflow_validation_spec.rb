require "rails_helper"

RSpec.describe WorkflowValidation do

  describe '#allowed_event_and_action?' do
    let(:step_instructions) { {} }

    context 'when we feed a valid extractor payload from GitHub' do
      let(:scm_extractor_payload) do
        {
          scm: 'github',
          event: 'pull_request',
          action: action
        }
      end

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
