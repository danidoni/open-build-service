module Workflows
  class ArtifactsCollector
    def initialize(step:, workflow_run_id:)
      @step = step
      @workflow_run_id = workflow_run_id
    end

    # TODO: test multibuilds and new approach with paths for configure_repositories
    def call
      artifacts = case @step.class.name
                  when 'Workflow::Step::BranchPackageStep', 'Workflow::Step::LinkPackageStep'
                    {
                      source_project: @step.step_instructions[:source_project],
                      source_package: @step.step_instructions[:source_package],
                      target_project: @step.target_project_name,
                      target_package: @step.target_package_name
                    }
                  when 'Workflow::Step::RebuildPackage'
                    {
                      project: @step.step_instructions[:project],
                      package: @step.step_instructions[:package]
                    }
                  when 'Workflow::Step::ConfigureRepositories'
                    # We only need the repositories' names and their archtectures.
                    repositories_and_architectures = @step.step_instructions[:repositories].map do |repository|
                      repository.delete(:target_project)
                      repository.delete(:target_repository)
                      repository
                    end

                    {
                      project: @step.step_instructions[:project],
                      repositories: repositories_and_architectures
                    }
                  end

      WorkflowArtifactsPerStep.find_or_create_by(workflow_run_id: @workflow_run_id, step: @step.class.name, artifacts: artifacts.to_json)
    end
  end
end
