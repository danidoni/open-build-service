require 'rails_helper'

RSpec.describe EventReceiversFetcher, type: :service do
  # Create package with an inherited maintainer
  let!(:project) { create(:confirmed_user, :with_home).home_project }
  let!(:package) { create(:package, project: project) }

  # Create event receivers
  let!(:user) { create(:confirmed_user) }
  let!(:group) { create(:group) }
  let!(:user_in_group) { create(:groups_user, user: create(:confirmed_user), group: group).user }
  let!(:no_email_user_in_group) { create(:groups_user, user: create(:confirmed_user), group: group, email: false).user }

  # Mark user and group as maintainer of the package
  let!(:receiver_role) { :target_maintainer }
  # TODO: Only explicit maintainers, so for example not maintainers inherited from a project, are considered in the event receivers. If no explicit maintainers are present, then implicit maintainers are considered.
  #       In the case of pass-otp, only dmarcoux and kbabioch are returned as receivers since they are the only explicit maintainers. Every other user and group is implicit (so inherited from the project security:privacy)
  let!(:relationship_package_user) { create(:relationship_package_user, package: package, user: user, role: Role.find_by_title('maintainer')) }
  let!(:relationship_package_group) { create(:relationship_package_group, package: package, group: group, role: Role.find_by_title('maintainer')) }

  # Trigger event by submitting a request to the package maintained by user and group
  let!(:bs_request) { create(:bs_request_with_submit_action, state: :new, target_package: package) }

  describe '#call' do
    subject { described_class.new(Event::RequestCreate.first, receiver_role).call }

    context 'when gathering event receivers for a requested created on a package' do
      # TODO: Rephrase this.... it's HUGEEEEE
      it 'returns all package explicit (not inherited) maintainers, so users, group with an email and, group members with email subscription enabled' do
        is_expected.to match_array([user, group, user_in_group])
      end
    end
  end
end
