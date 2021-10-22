require 'rails_helper'

RSpec.describe SourcediffTabComponent, type: :component, vcr: true do
  let(:user) { create(:confirmed_user, :with_home, login: 'tux') }
  let(:target_project) { create(:project, name: 'target_project') }
  let(:source_project) { create(:project, :as_submission_source, name: 'source_project') }
  let(:target_package) { create(:package, name: 'target_package', project: target_project) }
  let(:source_package) { create(:package, name: 'source_package', project: source_project) }
  let(:submit_request) do
    create(:bs_request_with_submit_action,
           target_package: target_package,
           source_package: source_package)
  end

  context 'shows the correct changes' do
    let!(:request) { submit_request }
    let!(:opts) { { filelimit: nil, tarlimit: nil, diff_to_superseded: nil, diffs: true, cacheonly: 1 } }

    before do
      User.session = create(:admin_user)
      action = request.send(:action_details, opts, xml: request.bs_request_actions.last)
      render_inline(described_class.new(bs_request: request, action: action, active: action[:name], index: 0, refresh: action[:diff_not_cached])).to_html
    end

    it do
      expect(rendered_component).to have_text('Submit package')
    end

    it do
      expect(rendered_component).to have_text('to package')
    end

    it do
      expect(rendered_component).to have_link(source_project.name, href: Rails.application.routes.url_helpers.project_show_path(source_project.name))
    end

    it do
      expect(rendered_component).to have_link(source_package.name, href: Rails.application.routes.url_helpers.package_show_path(source_project.name, source_package.name))
    end

    it do
      expect(rendered_component).to have_link(target_project.name, href: Rails.application.routes.url_helpers.project_show_path(target_project.name))
    end

    it do
      expect(rendered_component).to have_link(target_package.name, href: Rails.application.routes.url_helpers.package_show_path(target_project.name, target_package.name))
    end

    it do
      expect(rendered_component).to have_text('No newline at end of file')
    end
  end
end