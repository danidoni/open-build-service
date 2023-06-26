module Workflows
  class YAMLToWorkflowsService
    include WorkflowPlaceholderVariablesInstrumentation # for track_placeholder_variables

    # If the order of the values in this constant change, do not forget to change the mapping of the placeholder variable values
    SUPPORTED_PLACEHOLDER_VARIABLES = [:SCM_ORGANIZATION_NAME, :SCM_REPOSITORY_NAME, :SCM_PR_NUMBER, :SCM_COMMIT_SHA].freeze

    def initialize(yaml_file:, scm_webhook:, token:, workflow_run:)
      @yaml_file = yaml_file
      @scm_webhook = scm_webhook
      @token = token
      @workflow_run = workflow_run
    end

    def call
      create_workflows
    end

    private

    def create_workflows
      workflows_file_content = File.read(@yaml_file)
      @workflow_run.update(workflow_configuration_yaml: workflows_file_content)
      begin
        parsed_workflows_yaml = YAML.safe_load(parse_workflows_content(workflows_file_content))
      rescue Psych::SyntaxError, Token::Errors::WorkflowsYamlFormatError => e
        raise Token::Errors::WorkflowsYamlNotParsable, "Unable to parse #{@token.workflow_configuration_path}: #{e.message}"
      end

      parsed_workflows_yaml = extract_and_set_workflow_version(parsed_workflows_yaml: parsed_workflows_yaml)
      @workflow_run.update(workflow_configuration_names: parsed_workflows_yaml.keys.join(','))
      parsed_workflows_yaml
        .map do |_workflow_name, workflow_instructions|
        Workflow.new(workflow_instructions: workflow_instructions, scm_webhook: @scm_webhook, token: @token,
                     workflow_run: @workflow_run, workflow_version_number: @workflow_version_number)
      end
    end

    def parse_workflows_content(workflows_file_content)
      target_repository_full_name = @scm_webhook.payload.values_at(:target_repository_full_name, :path_with_namespace).compact.first
      scm_organization_name, scm_repository_name = target_repository_full_name.split('/')

      # The PR number is only present in webhook events for pull requests, so we have a default value in case someone doesn't use
      # this correctly. Here, we cannot inform users about this since we're processing the whole workflows file
      pr_number = @scm_webhook.payload.fetch(:pr_number, 'NO_PR_NUMBER')

      commit_sha = @scm_webhook.payload.fetch(:commit_sha)

      track_placeholder_variables(workflows_file_content)

      # Mapping the placeholder variables to their values from the webhook event payload
      placeholder_variables = SUPPORTED_PLACEHOLDER_VARIABLES.zip([scm_organization_name, scm_repository_name, pr_number, commit_sha]).to_h
      begin
        format(workflows_file_content, placeholder_variables)
      rescue ArgumentError => e
        raise Token::Errors::WorkflowsYamlFormatError, e.message
      end
    end

    def extract_and_set_workflow_version(parsed_workflows_yaml:)
      # Receive and delete the version key from the parsed yaml, so it is not
      # confused with a workflow name. Check if the version key points to a hash
      # incase 'version' is the name of a workflow e.g. {"version"=>1.1, "version"=>{"steps"=>[{"trigger_services"...
      @workflow_version_number ||= parsed_workflows_yaml.delete('version') unless parsed_workflows_yaml['version'].is_a?(Hash)
      parsed_workflows_yaml
    end
  end
end
