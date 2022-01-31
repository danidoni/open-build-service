class WorkflowRunArtifactsLinksComponentPreview < ViewComponent::Preview
  require 'factory_bot'
  include FactoryBot::Syntax::Methods

  def with_branch_package_step
    user = User.first
    extractor_payload = {
      scm: 'github',
      action: 'reopened',
      event: 'pull_request',
      pr_number: 4,
      target_repository_full_name: 'openSUSE/open-build-service'
    }
    token = Token.first
    scm_webhook = ScmWebhook.new(payload: extractor_payload)
    step = Workflow::Step::BranchPackageStep.new({
                                step_instructions: {
                                  source_project: 'OBS:Server:Unstable',
                                  source_package: 'obs-server',
                                  target_project: 'OBS:Server:Unstable:CI'
                                },
                                scm_webhook: scm_webhook,
                                token: token
                              })
    workflow_run = WorkflowRun.first
    artifacts = {
      source_project: step.step_instructions[:source_project],
      source_package: step.step_instructions[:source_package],
      target_project: step.target_project_name,
      target_package: step.target_package_name
    }.as_json
    artifact_per_step = WorkflowArtifactsPerStep.new(workflow_run: workflow_run, artifacts: artifacts, step: step)
    render(WorkflowRunArtifactsLinksComponent.new(artifact_per_step: artifact_per_step))
  end

  def with_link_package
    render(ExampleComponent.new(title: "This is a really long title to see how the component renders this"))
  end

  def with_configure_repositories
    render(ExampleComponent.new(title: "This component accepts a block of content")) do
      tag.div do
        content_tag(:span, "Hello")
      end
    end
  end

  def with_rebuild_package
  end
end
