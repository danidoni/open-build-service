class WorkflowRunArtifactsLinksComponent < ApplicationComponent
  attr_reader :artifact_per_step, :step, :artifacts

  def initialize(artifact_per_step:)
    super
    @artifact_per_step = artifact_per_step
    @step = @artifact_per_step.step
    @artifacts = @artifact_per_step.artifacts
  end
  
  def artifacts_links(context)
    # TODO: Recover from json parsing errors
    # artifacts will contain
    #  {
    #    "target_project": "home:Iggy:branches:home:Admin",
    #    "target_package": "ruby"
    #  }
    case step
    when 'Workflow::Step::BranchPackageStep'
      context.package_show_path(project: artifacts['target_project'], package: artifacts['target_package'])
    # TODO: Write the same for link package step, configure repositories step, rebuild package
    else
      "#"
    end
  end
end