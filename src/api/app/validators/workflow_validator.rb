class WorkflowValidator < ActiveModel::Validator
  def initialize(options)
    super
    @scm_extractor_payload = options[:scm_extractor_payload]
  end

  def validate(workflow)
    @scm_extractor_payload = workflow.scm_extractor_payload
    new_pull_request? || updated_pull_request?
  end

  def updated_pull_request?
    (github_pull_request? && @scm_extractor_payload[:action] == 'synchronize') ||
      (gitlab_merge_request? && @scm_extractor_payload[:action] == 'update')
  end

  private

  def github_pull_request?
    @scm_extractor_payload[:scm] == 'github' && @scm_extractor_payload[:event] == 'pull_request'
  end

  def gitlab_merge_request?
    @scm_extractor_payload[:scm] == 'gitlab' && @scm_extractor_payload[:event] == 'Merge Request Hook'
  end

  def new_pull_request?
    (github_pull_request? && @scm_extractor_payload[:action] == 'opened') ||
      (gitlab_merge_request? && @scm_extractor_payload[:action] == 'open')
  end
end
