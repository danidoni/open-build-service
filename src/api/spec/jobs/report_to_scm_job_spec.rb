require 'rails_helper'

RSpec.describe ReportToScmJob, vcr: false do
  let(:user) { create(:confirmed_user, login: 'foolano') }
  let(:token) { Token::Workflow.create(user: user) }
  let(:project) { create(:project, name: 'project_1', maintainer: user) }
  let(:package) { create(:package, name: 'package_1', project: project) }
  let(:repository) { create(:repository, name: 'repository_1', project: project) }
  let(:event) { Event::BuildSuccess.create({ project: project.name, package: package.name, repository: repository.name, reason: 'foo' }) }
  let(:event_subscription) { EventSubscription.create(token: token, user: user, package: package, receiver_role: 'reader', payload: 'foo', eventtype: 'Event::BuildSuccess') }

  shared_examples 'not reporting to the SCM' do
    it { expect(event.reload.undone_jobs).to be_positive }
    it { expect(subject).to be_falsey }

    it {
      subject
      expect(event.reload.undone_jobs).to be_zero
    }
  end

  describe '#perform' do
    subject { described_class.perform_now(event.id) }

    context 'happy path' do
      before do
        event
        event_subscription
      end

      it { expect(event.reload.undone_jobs).to be_positive }
      it { expect(subject).to be_truthy }

      it {
        subject
        expect(event.reload.undone_jobs).to be_zero
      }
    end

    context 'when using a non-allowed event' do
      let(:event) do
        Event::Commit.create(project: project.name, package: package.name)
      end

      before do
        event
        event_subscription
      end

      it_behaves_like 'not reporting to the SCM'
    end

    context 'when the event is for some other project than the subscribed one' do
      let(:event) { Event::BuildSuccess.create(project: 'some:other:project', package: package.name, repository: repository.name, reason: 'foo') }

      before do
        event
        event_subscription
      end

      it_behaves_like 'not reporting to the SCM'
    end

    context 'when the event is for some other package than the subscribed one' do
      let(:event) { Event::BuildSuccess.create(project: project.name, package: 'some_other_package', repository: repository.name, reason: 'foo') }

      before do
        event
        event_subscription
      end

      it_behaves_like 'not reporting to the SCM'
    end

    context 'when the reporting raises an error' do
      let(:event) { Event::BuildSuccess.create(project: project.name, package: package.name, repository: repository.name, reason: 'foo') }

      before do
        allow_any_instance_of(SCMStatusReporter).to receive(:call).and_raise(StandardError, '42') # rubocop:disable RSpec/AnyInstance
        event
        event_subscription
      end

      it {
        subject
        expect(event.reload.undone_jobs).to be_zero
      }
    end
  end
end
