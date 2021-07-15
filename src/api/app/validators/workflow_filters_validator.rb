class WorkflowFiltersValidator < ActiveModel::Validator

  def validate(record)
    @scm_extractor_payload = record.scm_extractor_payload
    @workflow = record
  end

  private

  def valid_workflow?
    # Filters aren't mandatory in a workflow
    return unless @workflow.key?(:filters)

    raise Token::Errors::UnsupportedWorkflowFilters, "Unsupported filters: #{@unsupported_filters.keys.to_sentence}" if unsupported_filters?

    return unless unsupported_filter_types?

    raise Token::Errors::UnsupportedWorkflowFilterTypes,
          "Filters #{@unsupported_filter_types.to_sentence} have unsupported keys. #{Workflow::SUPPORTED_FILTER_TYPES.to_sentence} are the only supported keys."
  end

  def unsupported_filters?
    @unsupported_filters ||= @workflow[:filters].select { |key, _value| Workflow::SUPPORTED_FILTERS.exclude?(key.to_sym) }

    @unsupported_filters.present?
  end

  def unsupported_filter_types?
    @unsupported_filter_types = []

    @workflow[:filters].each do |filter, value|
      @unsupported_filter_types << filter unless value.keys.all? { |filter_type| Workflow::SUPPORTED_FILTER_TYPES.include?(filter_type.to_sym) }
    end

    @unsupported_filter_types.present?
  end
end
