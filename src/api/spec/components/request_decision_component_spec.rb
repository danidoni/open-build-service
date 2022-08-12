require 'rails_helper'

RSpec.describe RequestDecisionComponent, type: :component do
  before do
    render_inline(described_class.new(bs_request: request,
                                      actions: actions,
                                      is_target_maintainer: is_target_maintainer,
                                      is_author: is_author))
  end

  context 'when the user is not the author of the request' do
    context 'and is not a target maintainer eiher' do
      let(:request) { create(:submit_request) }
      let(:actions) { [] }
      let(:is_target_maintainer) { false }
      let(:is_author) { true }

      it 'does not render anything' do
        expect(rendered_content).to be_blank
      end
    end

    context 'but is the target maintainer' do
      context 'and the target is in state new' do
        let(:request) { create(:bs_request_with_submit_action, state: 'new') }
        let(:actions) { [] }
        let(:is_target_maintainer) { false }
        let(:is_author) { true }

        it 'renders the Accept request button' do
          expect(rendered_content).to have_text('Accept request')
        end
      end
    end
  end

  context 'when the user is the author of the request' do
    context 'but it is not a target maintainer' do
      context 'and the request is in state new' do
        it 'renders the Revoke request button'
      end

      context 'and the request is in state review' do
        it 'renders the Revoke request button'
      end

      context 'and the request is in state declined' do
        it 'renders the Revoke request button'
      end
    end

    context 'and it is a target maintainer too' do
      context 'and the request is in state new' do
        it 'renders the Revoke request button'
      end

      context 'and the request is in state review' do
        it 'renders the Revoke request button'
      end

      context 'and the request is in state declined' do
        it 'renders the Revoke request button'
      end
    end
  end

  context 'when the user can revoke a request' do
    it 'renders the Revoke request button'
  end

  context 'when the user can reopen a request' do
    it 'renders the Reopen request button'
  end

  context 'when the user can accept a request' do
    it 'renders the Accept request button'
  end

  context 'when the user can decline a request' do
    it 'renders the Decline request button'
  end
end
