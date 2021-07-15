class WorkflowValidator < ActiveModel::Validator

  # We want to validate
  # - All the steps in the current workflow are supported
  # - All the filter are supported
  # - All the filter types are supported.
  # - The incoming event is what we expect (pull_request or "Merge Request Hook")
  # - The incoming action, in combination with the event, is correct.

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

  def valid_steps?
    unsupported_steps.none? && !invalid_steps?
  end

  # TODO: move to the WorkflowValidator
  def valid_workflow?

    raise Token::Errors::InvalidWorkflowStepDefinition, "Invalid workflow step definition: #{errors.to_sentence}" unless
      valid?

    # Filters aren't mandatory in a workflow
    return unless @workflow.key?(:filters)

    raise Token::Errors::UnsupportedWorkflowFilters, "Unsupported filters: #{@unsupported_filters.keys.to_sentence}" if unsupported_filters?

    return unless unsupported_filter_types?

    raise Token::Errors::UnsupportedWorkflowFilterTypes,
          "Filters #{@unsupported_filter_types.to_sentence} have unsupported keys. #{SUPPORTED_FILTER_TYPES.to_sentence} are the only supported keys."
  end


  def unsupported_steps
    @unsupported_steps ||= workflow_steps.each_with_object([]) do |step_definition, acc|
      rejected_steps = step_definition.reject { |step_name, _| SUPPORTED_STEPS.key?(step_name) }
      rejected_steps.empty? ? acc : acc << rejected_steps
    end
  end

  def errors
    unsupported_steps.each_with_object([]) do |step_definition, acc|
      step_definition.each do |step_name, _|
        acc << "'#{step_name}' is not a supported step"
      end
      acc
    end
  end

  def invalid_steps?
    steps.reject(&:valid?).any?
  end

  def unsupported_filters?
    @unsupported_filters ||= @workflow[:filters].select { |key, _value| SUPPORTED_FILTERS.exclude?(key.to_sym) }

    @unsupported_filters.present?
  end

  def unsupported_filter_types?
    @unsupported_filter_types = []

    @workflow[:filters].each do |filter, value|
      @unsupported_filter_types << filter unless value.keys.all? { |filter_type| SUPPORTED_FILTER_TYPES.include?(filter_type.to_sym) }
    end

    @unsupported_filter_types.present?
  end

end
